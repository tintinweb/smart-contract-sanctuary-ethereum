// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {IERC721, IERC165, IERC721Metadata} from "./interfaces/IERC721.sol";
import {INuggftV1Migrator} from "./interfaces/nuggftv1/INuggftV1Migrator.sol";
import {IDotnuggV1} from "dotnugg-v1-core/IDotnuggV1.sol";
import {INuggftV1Stake} from "./interfaces/nuggftv1/INuggftV1Stake.sol";
import {INuggftV1Proof} from "./interfaces/nuggftv1/INuggftV1Proof.sol";

import {INuggftV1} from "./interfaces/nuggftv1/INuggftV1.sol";

import {NuggftV1Loan} from "./core/NuggftV1Loan.sol";
import {NuggftV1Proof} from "./core/NuggftV1Proof.sol";
import {NuggftV1Globals} from "./core/NuggftV1Globals.sol";

import {DotnuggV1Lib} from "dotnugg-v1-core/DotnuggV1Lib.sol";

import {decodeMakingPrettierHappy} from "./libraries/BigOleLib.sol";

/// @title NuggftV1
/// @author nugg.xyz - danny7even and dub6ix - 2022
contract NuggftV1 is IERC721, IERC721Metadata, NuggftV1Loan {
	constructor() payable {}

	/// @inheritdoc INuggftV1Stake
	function migrate(uint24 tokenId) external {
		if (migrator == address(0)) _panic(Error__0x81__MigratorNotSet);

		// stores the proof before deleting the nugg
		uint256 proof = proofOf(tokenId);

		uint96 ethOwed = subStakedShare(tokenId);

		INuggftV1Migrator(migrator).nuggftMigrateFromV1{value: ethOwed}(tokenId, proof, msg.sender);

		emit MigrateV1Sent(migrator, tokenId, bytes32(proof), msg.sender, ethOwed);
	}

	/// @notice removes a staked share from the contract,
	/// @dev this is the only way to remove a share
	/// @dev caculcates but does not handle dealing the eth - which is handled by the two helpers above
	/// @dev ensures the user is the owner of the nugg
	/// @param tokenId the id of the nugg being unstaked
	/// @return ethOwed -> the amount of eth owed to the unstaking user - equivilent to "ethPerShare"
	function subStakedShare(uint24 tokenId) internal returns (uint96 ethOwed) {
		uint256 cache = agency[tokenId];

		_repanic(address(uint160(cache)) == msg.sender && uint8(cache >> 254) == 0x01, Error__0x77__NotOwner);

		cache = stake;

		// handles all logic not related to staking the nugg
		delete agency[tokenId];
		delete proof[tokenId];

		ethOwed = calculateEthPerShare(cache);

		cache -= 1 << 192;
		cache -= uint256(ethOwed) << 96;

		stake = cache;

		emit Stake(bytes32(cache));
		emit Transfer(msg.sender, address(0), tokenId);
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return
			interfaceId == type(IERC721).interfaceId || //
			interfaceId == type(IERC721Metadata).interfaceId ||
			interfaceId == type(IERC165).interfaceId;
	}

	/// @inheritdoc IERC721Metadata
	function name() public pure override returns (string memory) {
		return "Nugg Fungible Token V1";
	}

	/// @inheritdoc IERC721Metadata
	function symbol() public pure override returns (string memory) {
		return "NUGGFT";
	}

	/// @inheritdoc IERC721Metadata
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory res) {
		res = string(
			dotnuggv1.encodeJson(
				abi.encodePacked(
					'{"name":"NUGGFT","description":"Nugg Fungible Token V1","image":"',
					imageURI(tokenId),
					'","properites":',
					xnuggftv1.ploop(uint24(tokenId)),
					"}"
				),
				true
			)
		);
	}

	/// @inheritdoc INuggftV1Proof
	function imageURI(uint256 tokenId) public view override returns (string memory res) {
		res = dotnuggv1.exec(decodedCoreProofOf(uint24(tokenId)), true);
	}

	/// @inheritdoc INuggftV1Proof
	function imageSVG(uint256 tokenId) public view override returns (string memory res) {
		res = dotnuggv1.exec(decodedCoreProofOf(uint24(tokenId)), false);
	}

	/// this may seem like the dumbest function of all time - and it is
	/// it allows us to break up the "gas" usage over multiple view calls
	/// it increases the chance that services like the graph will compute the dotnugg image
	function image123(
		uint256 tokenId,
		bool base64,
		uint8 chunk,
		bytes calldata prev
	) public view override returns (bytes memory res) {
		if (chunk == 1) {
			res = abi.encode(dotnuggv1.read(decodedCoreProofOf((uint24(tokenId)))));
		} else if (chunk == 2) {
			(uint256[] memory calced, uint256 dat) = dotnuggv1.calc(decodeMakingPrettierHappy(prev));
			res = abi.encode(calced, dat);
		} else if (chunk == 3) {
			(uint256[] memory calced, uint256 dat) = abi.decode(prev, (uint256[], uint256));
			res = bytes(dotnuggv1.svg(calced, dat, base64));
		}
	}

	/// @inheritdoc IERC721
	function ownerOf(uint256 tokenId) public view override returns (address res) {
		res = _ownerOf(uint24(tokenId), epoch());

		if (res == address(0)) {
			// if (proofOf(uint24(tokenId)) != 0) {
			//     return address(this);
			// }
			_panic(Error__0x78__TokenDoesNotExist);
		}
	}

	function _ownerOf(uint256 tokenId, uint24 epoch) internal view returns (address res) {
		uint256 cache = agencyOf(uint24(tokenId));

		if (cache == 0) {
			// if (proofOf(uint24(tokenId)) != 0) {
			//     return address(this);
			// }
			return address(0);
		}

		if (cache >> 254 == 0x03 && (cache << 2) >> 232 >= epoch) {
			return address(this);
		}

		return address(uint160(cache));
	}

	function tokensOf(address you) external view override returns (uint24[] memory res) {
		res = new uint24[](10000);

		uint24 iter = 0;

		uint24 epoch = epoch();

		for (uint24 i = 1; i < epoch; i++) if (you == _ownerOf(i, epoch)) res[iter++] = i;

		(uint24 start, uint24 end) = premintTokens();

		for (uint24 i = start; i < end; i++) if (you == _ownerOf(i, epoch)) res[iter++] = i;

		assembly {
			mstore(res, iter)
		}
	}

	/// @inheritdoc IERC721
	function balanceOf(address you) external view override returns (uint256 acc) {
		return this.tokensOf(you).length;
	}

	/// @inheritdoc IERC721
	function approve(address, uint256) external payable override {
		_panic(Error__0x69__Wut);
	}

	/// @inheritdoc IERC721
	function setApprovalForAll(address, bool) external pure override {
		_panic(Error__0x69__Wut);
	}

	/// @inheritdoc IERC721
	function getApproved(uint256) external pure override returns (address) {
		return address(0);
	}

	/// @inheritdoc IERC721
	function isApprovedForAll(address, address) external pure override returns (bool) {
		return false;
	}

	//prettier-ignore
	/// @inheritdoc IERC721
	function transferFrom(address, address, uint256) external payable override {
        _panic(Error__0x69__Wut);
    }

	//prettier-ignore
	/// @inheritdoc IERC721
	function safeTransferFrom(address, address, uint256) external payable override {
        _panic(Error__0x69__Wut);
    }

	//prettier-ignore
	/// @inheritdoc IERC721
	function safeTransferFrom(address, address, uint256, bytes memory) external payable override {
        _panic(Error__0x69__Wut);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata_URI {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
}

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 is IERC165 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 is IERC165 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata is IERC721 {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

// prettier-ignore

interface INuggftV1Migrator {
    event MigrateV1Accepted(address v1, uint24 tokenId, bytes32 proof, address owner, uint96 eth);

    function nuggftMigrateFromV1(uint24 tokenId, uint256 proof, address owner) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

// prettier-ignore
interface IDotnuggV1 {
    event Write(uint8 feature, uint8 amount, address sender);

    function register(bytes[] calldata data) external returns (IDotnuggV1 proxy);

    function protectedInit(bytes[] memory input) external;

    function read(uint8[8] memory ids) external view returns (uint256[][] memory data);

    function read(uint8 feature, uint8 pos) external view returns (uint256[] memory data);

    function exec(uint8[8] memory ids, bool base64) external view returns (string memory);

    function exec(uint8 feature, uint8 pos, bool base64) external view returns (string memory);

    function calc(uint256[][] memory reads) external view returns (uint256[] memory calculated, uint256 dat);

    function combo(uint256[][] memory reads, bool base64) external view returns (string memory data);

    function svg(uint256[] memory calculated, uint256 dat, bool base64) external pure returns (string memory res);

    function encodeJson(bytes memory input, bool base64) external pure returns (bytes memory data);

    function encodeSvg(bytes memory input, bool base64) external pure returns (bytes memory data);
}

interface IDotnuggV1File {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface INuggftV1Stake {
    event Extract(uint96 eth);

    event MigratorV1Updated(address migrator);

    event MigrateV1Sent(address v2, uint24 tokenId, bytes32 proof, address owner, uint96 eth);

    event Stake(bytes32 stake);

    function migrate(uint24 tokenId) external;

    // /// @notice burns a nugg from existance, dealing the eth worth of that share to the user
    // /// @dev should only be called directly
    // /// @param tokenId the id of the nugg being burned
    // function burn(uint24 tokenId) external;

    /// @notice returns the total "eps" held by the contract
    /// @dev this value not always equivilent to the "floor" price which can consist of perceived value.
    /// can be looked at as an "intrinsic floor"
    /// @dev this is the value that users will receive when their either burn or loan out nuggs
    /// @return res -> [current staked eth] / [current staked shares]
    function eps() external view returns (uint96);

    /// @notice returns the minimum eth that must be added to create a new share
    /// @dev premium here is used to push against dillution of supply through ensuring the price always increases
    /// @dev used by the front end
    /// @return res -> premium + protcolFee + ethPerShare
    function msp() external view returns (uint96);

    // function mspni() external view returns (uint96);

    /// @notice returns the amount of eth extractable by protocol
    /// @dev this will be
    /// @return res -> (PROTOCOL_FEE_FRAC * [all eth staked] / 10000) - [all previously extracted eth]
    function proto() external view returns (uint96);

    /// @notice returns the total number of staked shares held by the contract
    /// @dev this is equivilent to the amount of nuggs in existance
    function shares() external view returns (uint64);

    /// @notice same as shares
    /// @dev for external entities like etherscan
    function totalSupply() external view returns (uint256);

    /// @notice returns the total amount of staked eth held by the contract
    /// @dev can be used as the market-cap or tvl of all nuggft v1
    /// @dev not equivilent to the balance of eth the contract holds, which also has protocolEth ...
    /// + unclaimed eth from unsuccessful swaps + eth from current waps
    function staked() external view returns (uint96);

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                TRUSTED
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @notice sends the current protocolEth to the user and resets the value to zero
    /// @dev caller must be a trusted user
    function extract() external;

    /// @notice sets the migrator contract
    /// @dev caller must be a trusted user
    /// @param migrator the address to set as the migrator contract
    function setMigrator(address migrator) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface INuggftV1Proof {
    event Rotate(uint24 indexed tokenId, bytes32 proof);

    function proofOf(uint24 tokenId) external view returns (uint256 res);

    function tokensOf(address you) external view returns (uint24[] memory res);

    function premintTokens() external view returns (uint24 first, uint24 last);

    // prettier-ignore
    function rotate(uint24 tokenId, uint8[] calldata from, uint8[] calldata to) external;

    function imageURI(uint256 tokenId) external view returns (string memory);

    function imageSVG(uint256 tokenId) external view returns (string memory);

    function image123(
        uint256 tokenId,
        bool base64,
        uint8 chunk,
        bytes memory prev
    ) external view returns (bytes memory res);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {INuggftV1Stake} from "./INuggftV1Stake.sol";
import {INuggftV1Proof} from "./INuggftV1Proof.sol";
import {INuggftV1Swap} from "./INuggftV1Swap.sol";
import {INuggftV1Loan} from "./INuggftV1Loan.sol";
import {INuggftV1Epoch} from "./INuggftV1Epoch.sol";
import {INuggftV1Trust} from "./INuggftV1Trust.sol";
import {INuggftV1ItemSwap} from "./INuggftV1ItemSwap.sol";
import {INuggftV1Globals} from "./INuggftV1Globals.sol";

import {IERC721Metadata, IERC721} from "../IERC721.sol";

// prettier-ignore
interface INuggftV1 is
    IERC721,
    IERC721Metadata,
    INuggftV1Stake,
    INuggftV1Proof,
    INuggftV1Swap,
    INuggftV1Loan,
    INuggftV1Epoch,
    INuggftV1Trust,
    INuggftV1ItemSwap,
    INuggftV1Globals
{


}

interface INuggftV1Events {
    event Genesis(uint256 blocknum, uint32 interval, uint24 offset, uint8 intervalOffset, uint24 early, address dotnugg, address xnuggftv1, bytes32 stake);
    event OfferItem(uint24 indexed sellingTokenId, uint16 indexed itemId, bytes32 agency, bytes32 stake);
    event ClaimItem(uint24 indexed sellingTokenId, uint16 indexed itemId, uint24 indexed buyerTokenId, bytes32 proof);
    event SellItem(uint24 indexed sellingTokenId, uint16 indexed itemId, bytes32 agency, bytes32 proof);
    event Loan(uint24 indexed tokenId, bytes32 agency);
    event Rebalance(uint24 indexed tokenId, bytes32 agency);
    event Liquidate(uint24 indexed tokenId, bytes32 agency);
    event MigrateV1Accepted(address v1, uint24 tokenId, bytes32 proof, address owner, uint96 eth);
    event Extract(uint96 eth);
    event MigratorV1Updated(address migrator);
    event MigrateV1Sent(address v2, uint24 tokenId, bytes32 proof, address owner, uint96 eth);
    event Burn(uint24 tokenId, address owner, uint96 ethOwed);
    event Stake(bytes32 stake);
    event Rotate(uint24 indexed tokenId, bytes32 proof);
    event Mint(uint24 indexed tokenId, uint96 value, bytes32 proof, bytes32 stake, bytes32 agency);
    event Offer(uint24 indexed tokenId, bytes32 agency, bytes32 stake);
    event OfferMint(uint24 indexed tokenId, bytes32 agency, bytes32 proof, bytes32 stake);
    event Claim(uint24 indexed tokenId, address indexed account);
    event Sell(uint24 indexed tokenId, bytes32 agency);
    event TrustUpdated(address indexed user, bool trust);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {INuggftV1Loan} from "../interfaces/nuggftv1/INuggftV1Loan.sol";

import {NuggftV1Swap} from "./NuggftV1Swap.sol";

/// @author nugg.xyz - danny7even and dub6ix - 2022
abstract contract NuggftV1Loan is INuggftV1Loan, NuggftV1Swap {
    /// @inheritdoc INuggftV1Loan
    function loan(uint24[] calldata tokenIds) external override {
        uint96 amt = eps();

        uint256 active = epoch();

        assembly {
            function juke(x, L, R) -> b {
                b := shr(R, shl(L, x))
            }

            function panic(code) {
                mstore(0x00, Revert__Sig)
                mstore8(31, code)
                revert(27, 0x5)
            }

            // load the length of the calldata array
            let len := calldataload(sub(tokenIds.offset, 0x20))

            let mptr := mload(0x40)

            // calculate agency.slot storeage ptr
            mstore(add(mptr, 0x20), agency.slot)

            // prettier-ignore
            for { let i := 0 } lt(i, len) { i := add(i, 0x1) } {
                // get a tokenId from calldata and store it to mem pos 0x00
                mstore(mptr, calldataload(add(tokenIds.offset, mul(i, 0x20))))

                let agency__sptr := keccak256(mptr, 0x40)

                // load agency value from storage
                let agency__cache := sload(agency__sptr)

                // ensure the caller is the agent
                if iszero(eq(juke(agency__cache, 96, 96), caller())) {
                    panic(Error__0xA1__NotAgent)
                }

                // ensure the agent is the owner
                if iszero(eq(shr(254, agency__cache), 0x1)) {
                    panic(Error__0x77__NotOwner)
                }

                // compress amt into 70 bits
                amt := div(amt, LOSS)

                // update agency to reflect the loan

                // ==== agency[tokenId] ====
                //  flag  = LOAN(0x02)
                //  epoch = active
                //  eth   = eps / .1 gwei
                //  addr  = agent
                // =========================

                agency__cache := xor(caller(), xor(shl(160, amt), xor(shl(230, active), shl(254, 0x2))))

                // store updated agency
                // done before external call to prevent reentrancy
                sstore(agency__sptr, agency__cache)

                // decompress amt back to eth
                // amt becomes a floored to .1 gwei version of eps()
                // ensures amt stored in agency and eth sent to caller are the same
                amt := mul(amt, LOSS)

                // send accumulated value * LOSS to msg.sender
                switch iszero(extcodesize(caller()))
                case 1 {
                    pop(call(gas(), caller(), amt, 0, 0, 0, 0))
                }
                default {
                    // if someone really ends up here, just donate the eth
                    let pro := div(amt, PROTOCOL_FEE_FRAC)

                    let cache := add(sload(stake.slot), or(shl(96, sub(amt, pro)), pro))

                    sstore(stake.slot, cache)

                    mstore(0x00, cache)

                    log1(0x00, 0x20, Event__Stake)
                }

                // log2 with "Loan(uint24,bytes32)" topic
                mstore(add(mptr, 0x40), agency__cache)

                log2(add(mptr, 0x40), 0x20, Event__Loan, mload(mptr))
            }
        }
    }

    /// @inheritdoc INuggftV1Loan
    function liquidate(uint24 tokenId) external payable override {
        uint256 active = epoch();
        address itemHolder = address(xnuggftv1);

        assembly {
            function juke(x, L, R) -> b {
                b := shr(R, shl(L, x))
            }

            function panic(code) {
                mstore(0x00, Revert__Sig)
                mstore8(31, code)
                revert(27, 0x5)
            }

            let stake__cache := sload(stake.slot)

            let shrs := shr(192, stake__cache)

            let activeEps := div(juke(stake__cache, 64, 160), shrs)

            let mptr := mload(0x40)

            // ========= memory ==========
            //   0x00: tokenId
            //   0x20: agency.slot
            // ===========================

            mstore(mptr, tokenId)
            mstore(add(mptr, 0x20), agency.slot)

            let agency__sptr := keccak256(mptr, 64)

            let agency__cache := sload(agency__sptr)

            let loaner := juke(agency__cache, 96, 96)

            // ensure that the agency flag is LOAN
            if iszero(eq(shr(254, agency__cache), 0x02)) {
                panic(Error__0xA8__NotLoaned)
            }

            // check to see if msg.sender is the loaner
            if iszero(eq(caller(), loaner)) {
                // "is the loan past due"
                switch lt(add(juke(agency__cache, 2, 232), LIQUIDATION_PERIOD), active)
                case 1 {
                    // if the loan is past due, then the liquidator recieves the nugg
                    // this transfer event is the only extra logic required here since the
                    // ... agency is updated to reflect "caller()" as the owner at the end
                    log4(0x00, 0x00, Event__Transfer, loaner, caller(), tokenId)

                    mstore(0x00, tokenId)
                    mstore(0x20, proof.slot)

                    let _proof := sload(keccak256(0x00, 0x40))

                    mstore(0x00, Function__transferBatch)
                    mstore(0x20, _proof)
                    mstore(0x40, address())
                    mstore(0x60, caller())

                    pop(call(gas(), itemHolder, 0x00, 0x1C, 0x64, 0x00, 0x00))
                }
                default {
                    // if not, then we revert.
                    // only the "loaner" can liquidate unless the loan is past due
                    panic(Error__0xA6__NotAuthorized)
                }
            }

            // parse agency for principal, converting it back to eth
            // represents the value that has been sent to the user for this loan
            let principal := mul(juke(agency__cache, 26, 186), LOSS)

            // the amount of value earned by this token since last rebalance
            // must be computed because fee needs to be paid
            // increase in earnings per share since last rebalance
            let earn := sub(activeEps, principal)

            // true fee
            let fee := add(div(principal, REBALANCE_FEE_BPS), principal)

            let value := add(earn, callvalue())

            if lt(value, fee) {
                panic(Error__0xA7__LiquidationPaymentTooLow)
            }

            earn := sub(value, fee)

            fee := sub(fee, principal)

            let pro := div(fee, PROTOCOL_FEE_FRAC)

            stake__cache := add(stake__cache, or(shl(96, sub(fee, pro)), pro))

            sstore(stake.slot, stake__cache)

            /////////////////////////////////////////////////////////////////////

            // update agency to return ownership of the token
            // done before external call to prevent reentrancy

            // ==== agency[tokenId] =====
            //     flag  = OWN(0x01)
            //     epoch = 0
            //     eth   = 0
            //     addr  = msg.sender
            // =========================

            agency__cache := or(caller(), shl(254, 0x01))

            sstore(agency__sptr, agency__cache)

            /////////////////////////////////////////////////////////////////////

            // send accumulated value * LOSS to msg.sender
            if iszero(call(gas(), caller(), earn, 0, 0, 0, 0)) {
                // if someone really ends up here, just donate the eth
                pro := div(earn, PROTOCOL_FEE_FRAC)

                stake__cache := add(stake__cache, or(shl(96, sub(earn, pro)), pro))

                sstore(stake.slot, stake__cache)
            }

            /////////////////////////////////////////////////////////////////////

            // ========== event ==========
            // emit Stake(stake__cache)
            // ===========================

            mstore(0x00, stake__cache)
            log1(0x00, 0x20, Event__Stake)

            // ========== event ==========
            // emit Liquidate(tokenId, agency__cache)
            // ===========================

            mstore(0x00, agency__cache)
            log2(0x00, 0x20, Event__Liquidate, tokenId)
        }
    }

    /// @inheritdoc INuggftV1Loan
    function rebalance(uint24[] calldata tokenIds) external payable {
        uint256 active = epoch();

        assembly {
            function juke(x, L, R) -> b {
                b := shr(R, shl(L, x))
            }

            function panic(code) {
                mstore(0x00, Revert__Sig)
                mstore8(31, code)
                revert(27, 0x5)
            }

            // load the length of the calldata array
            let len := calldataload(sub(tokenIds.offset, 0x20))

            let stake__cache := sload(stake.slot)

            let shrs := shr(192, stake__cache)

            let activeEps := div(juke(stake__cache, 64, 160), shrs)

            // ======================================================================
            // memory layout as offset from mptr:
            // ==========================
            // 0x00: tokenId                keccak = agency[tokenId].slot = "agency__sptr"
            // 0x20: agency.slot
            // --------------------------
            // 0x40: agency__cache
            // --------------------------
            // 0x60: agents address[]
            // ==========================

            // store agency slot for continuous calculation of storage pointers
            mstore(0x20, agency.slot)

            // hold the cumlative value to send back to the user
            // it starts off with callvalue in case there is a fee for the user to pay
            // ...that is not covered by the amount earned
            let acc := callvalue()

            // holds the cumlitve fee of all tokens being rebalanced
            // this is the amount to stake
            let accFee := 0

            // prettier-ignore
            for { let i := 0 } lt(i, len) { i := add(i, 0x1) } {
                // get a tokenId from calldata and store it to mem pos 0x00
                mstore(0x00, calldataload(add(tokenIds.offset, mul(i, 0x20))))

                let agency__sptr := keccak256(0x00, 0x40)

                //
                let agency__cache := sload(agency__sptr)

                let agency__addr := juke(agency__cache, 96, 96)

                // make sure this token is loaned
                if iszero(eq(shr(254, agency__cache), 0x02)) {
                    panic(Error__0xA8__NotLoaned)
                }

                // is the caller different from the agent?
                if iszero(eq(caller(), agency__addr)) {
                    // if so: ensure the loan is expired
                    // why? - only after a loan has expired are the "earnings" up for grabs.
                    // otherwise only the loaner is entitled to them
                    // TODO subtract some amount from LIQUIDATION_PERIOD here, to give rebalancers a head start
                    if iszero(lt(add(juke(agency__cache, 2, 232), LIQUIDATION_PERIOD), active)) {
                        panic(Error__0xA4__ExpiredEpoch) // ERR:0x3B
                    }
                }

                // parse agency for principal, converting it back to eth
                // represents the value that has been sent to the user for this loan
                let principal := mul(juke(agency__cache, 26, 186), LOSS)

                // the amount of value earned by this token since last rebalance
                // must be computed because fee needs to be paid
                // increase in earnings per share since last rebalance
                let earn := sub(activeEps, principal)

                // the maximum fee that can be levied
                // let fee := earn

                // true fee
                let fee := div(principal, REBALANCE_FEE_BPS)

                let value := add(earn, acc)

                if lt(value, fee) {
                    panic(Error__0xAA__RebalancePaymentTooLow)
                }

                accFee := add(accFee, fee)

                acc := sub(value, fee)

                mstore(add(0x60, mul(i, 0xA0)), agency__addr)

                // set the agency temporarily to 1 to avoid reentrancy
                // reentrancy here referes to a tokenId being passed multiple times in the calldata array
                // the only value that actually matters here is the "flag", but since it is reset below
                // ... we can just set the entire agency to 1
                sstore(agency__sptr, 0x01)
            }

            let pro := div(accFee, PROTOCOL_FEE_FRAC)

            stake__cache := add(stake__cache, or(shl(96, sub(accFee, pro)), pro))

            sstore(stake.slot, stake__cache)

            let newPrincipal := div(juke(stake__cache, 64, 160), mul(shrs, LOSS))

            // prettier-ignore
            for { let i := 0 } lt(i, len) { i := add(i, 0x1) } {
                mstore(0x00, calldataload(add(tokenIds.offset, mul(i, 0x20))))

                let account := mload(add(0x60, mul(i, 0xA0)))

                // update agency to reflect new principle and epoch
                // ==== agency[tokenId] =====
                //     flag  = LOAN(0x02)
                //     epoch = active
                //     eth   = eps
                //     addr  = loaner
                // =========================
                let agency__cache := or(shl(254, 0x2), or(shl(230, active), or(shl(160, newPrincipal), account)))

                sstore(keccak256(0x00, 0x40), agency__cache)

                mstore(0x40, agency__cache)

                log2(0x40, 0x20, Event__Rebalance, mload(0x00))
            }

            // ======================================================================

            // send accumulated value * LOSS to msg.sender
            if iszero(call(gas(), caller(), acc, 0, 0, 0, 0)) {
                // if someone really ends up here, just donate the eth
                pro := div(acc, PROTOCOL_FEE_FRAC)

                stake__cache := add(stake__cache, or(shl(96, sub(acc, pro)), pro))

                sstore(stake.slot, stake__cache)
            }

            mstore(0x00, stake__cache)
            log1(0x00, 0x20, Event__Stake)
        }
    }

    function calc(uint96 principal, uint96 activeEps)
        internal
        pure
        returns (
            // uint96 debt,
            uint96 fee,
            uint96 earn
        )
    {
        // principal can never be below activeEps
        // assert(principal <= activeEps);

        assembly {
            fee := sub(activeEps, principal)

            let checkFee := div(principal, REBALANCE_FEE_BPS)

            if gt(fee, checkFee) {
                earn := sub(fee, checkFee)
                fee := checkFee
            }
        }
    }

    /// @inheritdoc INuggftV1Loan
    function debt(uint24 tokenId)
        public
        view
        returns (
            bool isLoaned,
            address account,
            uint96 prin,
            uint96 fee,
            uint96 earn,
            uint24 expire
        )
    {
        uint96 activeEps = eps();

        assembly {
            let mptr := mload(0x40)

            mstore(mptr, tokenId)
            mstore(add(mptr, 0x20), agency.slot)

            let agency__cache := sload(keccak256(mptr, 0x40))

            if iszero(eq(shr(254, agency__cache), 0x02)) {
                return(0x00, 0x00)
            }

            isLoaned := 0x01

            expire := add(shr(230, agency__cache), LIQUIDATION_PERIOD)

            account := agency__cache

            prin := mul(shr(186, shl(26, agency__cache)), LOSS)

            earn := sub(activeEps, prin)

            fee := div(prin, REBALANCE_FEE_BPS)
        }
    }

    /// @notice vfr: "Value For Rebalance"
    /// @inheritdoc INuggftV1Loan
    function vfr(uint24[] calldata tokenIds) external view returns (uint96[] memory vals) {
        vals = new uint96[](tokenIds.length);
        for (uint256 i = 0; i < vals.length; i++) {
            (bool ok, , , uint96 fee, uint96 earn, ) = debt(tokenIds[i]);

            if (!ok) continue;

            if (ok && fee > earn) {
                vals[i] = fee - earn;
            }
        }
    }

    /// @notice vfl: "Value For Liquidate"
    /// @inheritdoc INuggftV1Loan
    function vfl(uint24[] calldata tokenIds) external view returns (uint96[] memory vals) {
        vals = new uint96[](tokenIds.length);
        for (uint256 i = 0; i < vals.length; i++) {
            (bool ok, , uint96 prin, uint96 fee, uint96 earn, ) = debt(tokenIds[i]);

            if (ok && (prin = prin + fee) > earn) {
                vals[i] = prin - earn;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {INuggftV1Proof} from "../interfaces/nuggftv1/INuggftV1Proof.sol";
import {IERC1155, IERC165} from "../interfaces/IERC721.sol";
import {INuggftV1} from "../interfaces/nuggftv1/INuggftV1.sol";
import {xNuggftV1} from "../xNuggftV1.sol";

import {DotnuggV1Lib} from "dotnugg-v1-core/DotnuggV1Lib.sol";
import {IDotnuggV1} from "dotnugg-v1-core/IDotnuggV1.sol";

import {NuggftV1Epoch} from "./NuggftV1Epoch.sol";
import {NuggftV1Trust} from "./NuggftV1Trust.sol";

/// @author nugg.xyz - danny7even and dub6ix - 2022
abstract contract NuggftV1Proof is INuggftV1Proof, NuggftV1Epoch, NuggftV1Trust {
    using DotnuggV1Lib for IDotnuggV1;

    function calculateEarlySeed(uint24 tokenId) internal view returns (uint256 seed) {
        return uint256(keccak256(abi.encodePacked(tokenId, earlySeed)));
    }

    function premintTokens() public view returns (uint24 first, uint24 last) {
        first = MINT_OFFSET;

        last = first + early - 1;
    }

    function decodedCoreProofOf(uint24 tokenId) internal view returns (uint8[8] memory proof) {
        return DotnuggV1Lib.decodeProofCore(proofOf(tokenId));
    }

    /// @inheritdoc INuggftV1Proof
    function proofOf(uint24 tokenId) public view override returns (uint256 res) {
        if ((res = proof[tokenId]) != 0) return res;

        uint256 seed;

        (uint24 first, uint24 last) = premintTokens();

        if (tokenId >= first && tokenId <= last) {
            seed = calculateEarlySeed(tokenId);
        } else {
            uint24 epoch = epoch();

            if (tokenId == epoch + 1) epoch++;

            seed = calculateSeed(epoch);
        }

        if (seed != 0) return initFromSeed(seed);

        _panic(Error__0xAD__InvalidZeroProof);
    }

    /// @inheritdoc INuggftV1Proof
    function rotate(
        uint24 tokenId,
        uint8[] calldata index0s,
        uint8[] calldata index1s
    ) external override {
        assembly {
            function juke(x, L, R) -> b {
                b := shr(R, shl(L, x))
            }

            function panic(code) {
                mstore(0x00, Revert__Sig)
                mstore8(31, code)
                revert(27, 0x5)
            }

            mstore(0x00, tokenId)
            mstore(0x20, agency.slot)
            let buyerTokenAgency := sload(keccak256(0x00, 0x40))

            // ensure the caller is the agent
            if iszero(eq(juke(buyerTokenAgency, 96, 96), caller())) {
                panic(Error__0xA2__NotItemAgent)
            }

            let flag := shr(254, buyerTokenAgency)

            // ensure the caller is really the agent
            // aka is the nugg claimed
            if and(eq(flag, 0x3), iszero(iszero(juke(buyerTokenAgency, 2, 232)))) {
                panic(Error__0xA3__NotItemAuthorizedAgent)
            }

            mstore(0x20, proof.slot)

            let proof__sptr := keccak256(0x00, 0x40)

            let _proof := sload(proof__sptr)

            // extract length of tokenIds array from calldata
            let len := calldataload(sub(index0s.offset, 0x20))

            // ensure arrays the same length
            if iszero(eq(len, calldataload(sub(index1s.offset, 0x20)))) {
                panic(Error__0x76__InvalidArrayLengths)
            }
            mstore(0x00, _proof)

            // prettier-ignore
            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                // tokenIds[i]
                let index0 := calldataload(add(index0s.offset, mul(i, 0x20)))

                // accounts[i]
                let index1 := calldataload(add(index1s.offset, mul(i, 0x20)))

                // prettier-ignore
                if or(or(or( // ================================================
                    iszero(index0),           // since we are working with external input here, we want
                    iszero(index1)),          // + to make sure the indexs passed are valid (1 <= x <= 16)
                    iszero(gt(16, index0))),   // FIXME - shouldnt this be 15?
                    iszero(gt(16, index1))
                 ) { panic(Error__0x73__InvalidProofIndex) } // ==============

                _proof := mload(0x00)

                let pos0 := mul(sub(15, index0), 0x2)
                let pos1 := mul(sub(15, index1), 0x2)
                let item0 := and(shr(mul(index0, 16), _proof), 0xffff)
                let item1 := and(shr(mul(index1, 16), _proof), 0xffff)

                mstore8(pos1, shr(8, item0))
                mstore8(add(pos1, 1), item0)
                mstore8(pos0, shr(8, item1))
                mstore8(add(pos0, 1), item1)
            }

            sstore(proof__sptr, mload(0x00))

            log2(0x00, 0x20, Event__Rotate, tokenId)
        }
    }

    function breaker(uint8 seed) internal pure returns (uint8) {
        if (seed >= 160) {
            return ((seed - 160) / 48) + 1;
        }
        return (seed / 32) + 3;
        /* [1=18.75%, 2=18.75%, 3=12.5%, 4=12.5%, 5=12.5%, 6=12.5%, 7=12.5%] */
    }

    // 0 = 8/8               = 8
    // 1 = 8/8 + 3/16 + 3/16 = 11
    // 2 = 8/8 + 3/16 + 3/16 = 11
    // 3 = 4/8 + 1/8 + 1/8   = 6
    // 4 = 4/8 + 1/8 + 1/8   = 6
    // 5 = 1/8 + 1/8 + 1/8   = 3
    // 6 = 1/8 + 1/8 + 1/8   = 3
    // 7 = 1/8 + 1/8 + 1/8   = 3
    function initFromSeed(uint256 seed) internal view returns (uint256 res) {
        uint8 selB = uint8((seed >> 16));
        uint8 selC = uint8((seed >> 24));
        uint8 selD = uint8((seed >> 32));

        if ((selB /= 32) <= 3) selB = 0; /* [4=12.5% 5=12.5%, 6=12.5%, 7=12.5%, 0=50%] */

        selC = breaker(selC);
        selD = breaker(selD);

        res |= uint256(dotnuggv1.searchToId(0, seed)) << 0x00;
        res |= uint256(dotnuggv1.searchToId(1, seed)) << 0x10;
        res |= uint256(dotnuggv1.searchToId(2, seed)) << 0x20;
        res |= uint256(dotnuggv1.searchToId(3, seed)) << 0x30;
        if (selB != 0) {
            res |= uint256(dotnuggv1.searchToId(selB, seed)) << (0x40);
        }
        res |= uint256(dotnuggv1.searchToId(selC, seed >> 40)) << (0x80);
        res |= uint256(dotnuggv1.searchToId(selD, seed >> 48)) << (0x90);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {IDotnuggV1} from "dotnugg-v1-core/IDotnuggV1.sol";
import {DotnuggV1} from "dotnugg-v1-core/DotnuggV1.sol";
import {IxNuggftV1} from "../interfaces/nuggftv1/IxNuggftV1.sol";
import {xNuggftV1} from "../xNuggftV1.sol";

import {NuggftV1Constants} from "./NuggftV1Constants.sol";
import {INuggftV1Globals} from "../interfaces/nuggftv1/INuggftV1Globals.sol";

/// @author nugg.xyz - danny7even and dub6ix - 2022
abstract contract NuggftV1Globals is NuggftV1Constants, INuggftV1Globals {
    mapping(uint24 => uint256) public override proof;
    mapping(uint24 => uint256) public override agency;
    mapping(uint16 => uint256) public override lastItemSwap;

    mapping(uint24 => mapping(address => uint256)) internal _offers;
    mapping(uint40 => mapping(uint24 => uint256)) internal _itemOffers;
    mapping(uint40 => uint256) internal _itemAgency;

    uint256 public override stake;
    address public override migrator;
    uint256 public immutable override genesis;
    IDotnuggV1 public immutable override dotnuggv1;
    IxNuggftV1 public immutable xnuggftv1;
    uint24 public immutable override early;

    uint256 internal immutable earlySeed;

    constructor() payable {
        genesis = (block.number / INTERVAL) * INTERVAL;

        earlySeed = uint256(keccak256(abi.encodePacked(block.number, msg.sender)));

        early = uint24(msg.value / STARTING_PRICE);

        dotnuggv1 = new DotnuggV1();

        xnuggftv1 = IxNuggftV1(new xNuggftV1());

        stake = (msg.value << 96) + (uint256(early) << 192);

        emit Genesis(genesis, uint16(INTERVAL), uint16(OFFSET), INTERVAL_SUB, early, address(dotnuggv1), address(xnuggftv1), bytes32(stake));
    }

    function multicall(bytes[] calldata data) external {
        // purposly not payable here
        unchecked {
            bytes memory a;
            bool success;

            for (uint256 i = 0; i < data.length; i++) {
                a = data[i];
                assembly {
                    success := delegatecall(gas(), address(), add(a, 32), mload(a), a, 5)
                    if iszero(success) {
                        revert(a, 5)
                    }
                }
            }
        }
    }

    function offers(uint24 tokenId, address account) public view override returns (uint256 value) {
        return _offers[tokenId][account];
    }

    function itemAgency(uint24 sellingTokenId, uint16 itemId) public view override returns (uint256 value) {
        return _itemAgency[uint40(sellingTokenId) | (uint40(itemId) << 24)];
    }

    function itemOffers(
        uint24 buyingTokenid,
        uint24 sellingTokenId,
        uint16 itemId
    ) public view override returns (uint256 value) {
        return _itemOffers[uint40(sellingTokenId) | (uint40(itemId) << 24)][buyingTokenid];
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {IDotnuggV1, IDotnuggV1File} from "./IDotnuggV1.sol";

/// @title DotnuggV1Lib
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @notice helper functions for working with dotnuggv1 files on chain
library DotnuggV1Lib {
    uint8 constant DOTNUGG_HEADER_BYTE_LEN = 25;

    uint8 constant DOTNUGG_RUNTIME_BYTE_LEN = 1;

    bytes18 internal constant PROXY_INIT_CODE = 0x69_36_3d_3d_36_3d_3d_37_f0_33_FF_3d_52_60_0a_60_16_f3;

    bytes32 internal constant PROXY_INIT_CODE_HASH = keccak256(abi.encodePacked(PROXY_INIT_CODE));

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        return toFixedPointString(value, 0);
    }

    /// @notice parses the external itemId into a feautre and position
    /// @dev this follows dotnugg v1 specification
    /// @param itemId -> the external itemId
    /// @return feat -> the feautre of the item
    /// @return pos -> the file storage position of the item
    function parseItemId(uint256 itemId) internal pure returns (uint8 feat, uint8 pos) {
        feat = uint8(itemId / 1000);
        pos = uint8(itemId % 1000);
    }

    /// @notice parses the external itemId into a feautre and position
    /// @dev this follows dotnugg v1 specification
    /// @return itemId -> the external itemId
    /// @param feat -> the feautre of the item
    /// @param pos -> the file storage position of the item
    function encodeItemId(uint8 feat, uint8 pos) internal pure returns (uint16 itemId) {
        return (uint16(feat) * 1000) + pos;
    }

    function itemIdToString(uint16 itemId, string[8] memory labels) internal pure returns (string memory) {
        (uint8 feat, uint8 pos) = parseItemId(itemId);
        return string.concat(labels[feat], " ", toString(pos));
    }

    function searchToId(
        IDotnuggV1 safe,
        uint8 feature,
        uint256 seed
    ) internal view returns (uint16 res) {
        return encodeItemId(feature, search(safe, feature, seed));
    }

    function lengthOf(IDotnuggV1 safe, uint8 feature) internal view returns (uint8) {
        return size(location(safe, feature));
    }

    function locationOf(IDotnuggV1 safe, uint8 feature) internal pure returns (address res) {
        return address(location(safe, feature));
    }

    function size(IDotnuggV1File pointer) private view returns (uint8 res) {
        assembly {
            // memory:
            // [0x00] 0x//////////////////////////////////////////////////////////////

            let scratch := mload(0x00)

            // the amount of items inside a dotnugg file are stored at byte #1 (0 based index)
            // here we copy that single byte from the file and store it in byte #31 of memory
            // this way, we can mload(0x00) to get the properly alignede integer from memory

            extcodecopy(pointer, 31, DOTNUGG_RUNTIME_BYTE_LEN, 0x01)

            // memory:                                           length of file  =  XX
            // [0x00] 0x////////////////////////////////////////////////////////////XX

            res := and(mload(0x00), 0xff)

            // clean the scratch space we dirtied
            mstore(0x00, scratch)

            // memory:
            // [0x00] 0x//////////////////////////////////////////////////////////////
        }
    }

    function location(IDotnuggV1 safe, uint8 feature) private pure returns (IDotnuggV1File res) {
        bytes32 h = PROXY_INIT_CODE_HASH;

        assembly {
            // [======================================================================
            let mptr := mload(0x40)

            // [0x00] 0x00000000000000000000000000000000000000000000000000000000000000
            // [0x20] 0x00000000000000000000000000000000000000000000000000000000000000
            // [0x40] 0x________________________FREE_MEMORY_PTR_______________________
            // =======================================================================]

            // [======================================================================
            mstore8(0x00, 0xff)
            mstore(0x01, shl(96, safe))
            mstore(0x15, feature)
            mstore(0x35, h)

            // [0x00] 0xff>_________________safe__________________>___________________
            // [0x20] 0x________________feature___________________>___________________
            // [0x40] 0x________________PROXY_INIT_CODE_HASH______////////////////////
            // =======================================================================]

            // 1 proxy #1 - dotnugg for nuggft (or a clone of dotnugg)
            // to calculate proxy #2 - address proxy #1 + feature(0-7) + PROXY#2_INIT_CODE
            // 8 proxy #2 - things that get self dest

            // 8 proxy #3 - nuggs
            // to calc proxy #3 = address proxy #2 + [feature(1-8)] = nonce
            // nonces for contracts start at 1

            // bytecode -> proxy #2 -> contract with items (dotnugg file) -> kills itelf

            // [======================================================================
            mstore(0x02, shl(96, keccak256(0x00, 0x55)))
            mstore8(0x00, 0xD6)
            mstore8(0x01, 0x94)
            mstore8(0x16, 0x01)

            // [0x00] 0xD694_________ADDRESS_OF_FILE_CREATOR________01////////////////
            // [0x20] ////////////////////////////////////////////////////////////////
            // [0x40] ////////////////////////////////////////////////////////////////
            // =======================================================================]

            res := shr(96, shl(96, keccak256(0x00, 0x17)))

            // [======================================================================
            mstore(0x00, 0x00)
            mstore(0x20, 0x00)
            mstore(0x40, mptr)

            // [0x00] 0x00000000000000000000000000000000000000000000000000000000000000
            // [0x20] 0x00000000000000000000000000000000000000000000000000000000000000
            // [0x40] 0x________________________FREE_MEMORY_PTR_______________________
            // =======================================================================]
        }
    }

    /// binary search usage inspired by implementation from fiveoutofnine
    /// [ OnMintGeneration.sol : MIT ] - https://github.com/fiveoutofnine/on-mint-generation/blob/719f19a10d19956c8414e421517d902ab3591111/src/OnMintGeneration.sol
    function search(
        IDotnuggV1 safe,
        uint8 feature,
        uint256 seed
    ) internal view returns (uint8 res) {
        IDotnuggV1File loc = location(safe, feature);

        uint256 high = size(loc);

        // prettier-ignore
        assembly {

            // we adjust the seed to be unique per feature and safe, yet still deterministic

            mstore(0x00, seed)
            mstore(0x20, or(shl(160, feature), safe))

            seed := keccak256( //-----------------------------------------
                0x00, /* [ seed                                  ]    0x20
                0x20     [ uint8(feature) | address(safe)        ] */ 0x40
            ) // ---------------------------------------------------------

            // normalize seed to be <= type(uint16).max
            // if we did not want to use weights, we could just mod by "len" and have our final value
            // without any calcualtion
            seed := mod(seed, 0xffff)

            //////////////////////////////////////////////////////////////////////////

            // Get a pointer to some free memory.
            // no need update pointer becasue after this function, the loaded data is no longer needed
            //    and solidity does not assume the free memory pointer points to "clean" data
            let A := mload(0x40)

            // Copy the code into memory right after the 32 bytes we used to store the len.
            extcodecopy(loc, add(0x20, A), add(DOTNUGG_RUNTIME_BYTE_LEN, 1), mul(high, 2))

            // adjust data pointer to make mload return our uint16[] index easily using below funciton
            A := add(A, 0x2)

            function index(arr, m) -> val {
                val := and(mload(add(arr, shl(1, m))), 0xffff)
            }

            //////////////////////////////////////////////////////////////////////////

            // each dotnuggv1 file includes a sorted weight list that we can use to convert "random" seeds into item numbers:

            // lets say we have an file containing 4 itmes with these as their respective weights:
            // [ 0.10  0.10  0.15  0.15 ]

            // then on chain, an array like this is stored: (represented in decimal for the example)
            // [ 2000  4000  7000  10000 ]

            // assuming we can only pass a seed between 0 and 10000, we know that:
            // - we have an 20% chance, of picking a number less than weight 1      -  0    < x < 2000
            // - we have an 20% chance, of picking a number between weights 1 and 2 -  2000 < x < 4000
            // - we have an 30% chance, of picking a number between weights 2 and 3 -  4000 < x < 7000
            // - we have an 30% chance, of picking a number between weights 3 and 4 -  7000 < x < 10000

            // now, all we need to do is pick a seed, say "6942", and search for which number it is between

            // the higher of which will be the value we are looking for

            // in our example, "6942" is between weights 2 and 3, so [res = 3]

            //////////////////////////////////////////////////////////////////////////

            // right most "successor" binary search
            // https://en.wikipedia.org/wiki/Binary_search_algorithm#Procedure_for_finding_the_rightmost_element

            let L := 0
            let R := high

            for { } lt(L, R) { } {
                let m := shr(1, add(L, R)) // == (L + R) / 2
                switch gt(index(A, m), seed)
                case 1  { R := m         }
                default { L := add(m, 1) }
            }

            // we add one because items are 1 base indexed, not 0
            res := add(R, 1)
        }
    }

    function rarity(
        IDotnuggV1 safe,
        uint8 feature,
        uint8 position
    ) internal view returns (uint16 res) {
        IDotnuggV1File loc = location(safe, uint8(feature));

        assembly {
            switch eq(position, 1)
            case 1 {
                extcodecopy(loc, 30, add(DOTNUGG_RUNTIME_BYTE_LEN, 1), 2)

                res := and(mload(0x00), 0xffff)
            }
            default {
                extcodecopy(loc, 28, add(add(DOTNUGG_RUNTIME_BYTE_LEN, 1), mul(sub(position, 2), 2)), 4)

                res := and(mload(0x00), 0xffffffff)

                let low := shr(16, res)

                res := sub(and(res, 0xffff), low)
            }
        }
    }

    function read(
        IDotnuggV1 safe,
        uint8 feature,
        uint8 position
    ) internal view returns (uint256[] memory res) {
        IDotnuggV1File loc = location(safe, feature);

        uint256 length = size(loc);

        require(position <= length && position != 0, "F:1");

        position = position - 1;

        uint32 startAndEnd = uint32(
            bytes4(readBytecode(loc, DOTNUGG_RUNTIME_BYTE_LEN + length * 2 + 1 + position * 2, 4))
        );

        uint32 begin = startAndEnd >> 16;

        return readBytecodeAsArray(loc, begin, (startAndEnd & 0xffff) - begin);
    }

    // adapted from rari-capital/solmate's SSTORE2.sol
    function readBytecodeAsArray(
        IDotnuggV1File file,
        uint256 start,
        uint256 len
    ) private view returns (uint256[] memory data) {
        assembly {
            let offset := sub(0x20, mod(len, 0x20))

            let arrlen := add(0x01, div(len, 0x20))

            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(add(len, 32), offset), 31), not(31))))

            // Store the len of the data in the first 32 byte chunk of free memory.
            mstore(data, arrlen)

            // Copy the code into memory right after the 32 bytes we used to store the len.
            extcodecopy(file, add(add(data, 32), offset), start, len)
        }
    }

    // adapted from rari-capital/solmate's SSTORE2.sol
    function readBytecode(
        IDotnuggV1File file,
        uint256 start,
        uint256 len
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to len and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(len, 32), 31), not(31))))

            // Store the len of the data in the first 32 byte chunk of free memory.
            mstore(data, len)

            // Copy the code into memory right after the 32 bytes we used to store the len.
            extcodecopy(file, add(data, 32), start, len)
        }
    }

    bytes16 private constant ALPHABET = "0123456789abcdef";

    function toHex(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    ///
    /// inspired by OraclizeAPI's implementation
    /// [ oraclizeAPI_0.4.25.sol : MIT ] - https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    function toFixedPointString(uint256 value, uint256 places) internal pure returns (string memory) {
        unchecked {
            if (value == 0) return "0";

            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }

            digits = places == 0 ? digits : (digits > places ? digits : places) + 1;

            bytes memory buffer = new bytes(digits);

            if (places != 0) buffer[digits - places - 1] = ".";

            while (digits != 0) {
                digits -= 1;
                if (buffer[digits] == ".") {
                    if (digits == 0) break;
                    digits -= 1;
                }

                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }

    function chunk(
        string memory input,
        uint8 chunks,
        uint8 index
    ) internal pure returns (string memory res) {
        res = input;

        if (chunks == 0) return res;

        assembly {
            let strlen := div(mload(res), chunks)

            let start := mul(strlen, index)

            if gt(strlen, sub(mload(res), start)) {
                strlen := sub(mload(res), start)
            }

            res := add(res, start)

            mstore(res, strlen)
        }
    }

    function decodeProof(uint256 input) internal pure returns (uint16[16] memory res) {
        unchecked {
            for (uint256 i = 0; i < 16; i++) {
                res[i] = uint16(input);
                input >>= 16;
            }
        }
    }

    function decodeProofCore(uint256 proof) internal pure returns (uint8[8] memory res) {
        unchecked {
            for (uint256 i = 0; i < 8; i++) {
                (uint8 feature, uint8 pos) = parseItemId(uint16(proof));
                if (res[feature] == 0) res[feature] = pos;
                proof >>= 16;
            }
        }
    }

    function encodeProof(uint8[8] memory ids) internal pure returns (uint256 proof) {
        unchecked {
            for (uint256 i = 0; i < 8; i++) proof |= ((i << 8) | uint256(ids[i])) << (i << 3);
        }
    }

    function encodeProof(uint16[16] memory ids) internal pure returns (uint256 proof) {
        unchecked {
            for (uint256 i = 0; i < 16; i++) proof |= uint256(ids[i]) << (i << 4);
        }
    }

    function props(uint16[16] memory ids, string[8] memory labels) internal pure returns (string memory) {
        unchecked {
            bytes memory res;

            for (uint8 i = 0; i < ids.length; i++) {
                (uint8 feature, uint8 pos) = parseItemId(ids[i]);
                if (ids[i] == 0) continue;
                res = abi.encodePacked(res, i != 0 ? "," : "", '"', labels[feature], "-", toString(uint8(pos)), '"');
            }
            return string(abi.encodePacked("[", res, "]"));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

function decodeMakingPrettierHappy(bytes memory input) pure returns (uint256[][] memory res){
    res = abi.decode(input, (uint256[][]));
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

// prettier-ignore

interface INuggftV1Swap {
    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param tokenId (uint24)
    /// @param agency  (bytes32) a parameter just like in doxygen (must be followed by parameter name)
    event Offer(uint24 indexed tokenId, bytes32 agency, bytes32 stake);

    event OfferMint(uint24 indexed tokenId, bytes32 agency, bytes32 proof, bytes32 stake);

    event PreMint(uint24 indexed tokenId, bytes32 proof, bytes32 nuggAgency, uint16 indexed itemId, bytes32 itemAgency);

    event Claim(uint24 indexed tokenId, address indexed account);

    event Sell(uint24 indexed tokenId, bytes32 agency);


    /* ///////////////////////////////////////////////////////////////////
                            STATE CHANGING
    /////////////////////////////////////////////////////////////////// */

    function offer(uint24 tokenId) external payable;

    function offer(
        uint24 tokenIdToClaim,
        uint24 nuggToBidOn,
        uint16 itemId,
        uint96 value1,
        uint96 value2
    ) external payable;

    function claim(
        uint24[] calldata tokenIds,
        address[] calldata accounts,
        uint24[] calldata buyingTokenIds,
        uint16[] calldata itemIds
    ) external;

    function sell(uint24 tokenId, uint96 floor) external;

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            VIEW FUNCTIONS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/



    function agencyOf(uint24 tokenId) external view returns (uint256);

    function itemAgencyOf(uint24 tokenId, uint16 itemId) external view returns (uint256);
    /// @notice calculates the minimum eth that must be sent with a offer call
    /// @dev returns 0 if no offer can be made for this oken
    /// @param tokenId -> the token to be offerd to
    /// @param sender -> the address of the user who will be delegating
    /// @return canOffer -> instead of reverting this function will return false
    /// @return nextMinUserOffer -> the minimum value that must be sent with a offer call
    /// @return currentUserOffer ->
    function check(address sender, uint24 tokenId)
        external
        view
        returns (
            bool canOffer,
            uint96 nextMinUserOffer,
            uint96 currentUserOffer,
            uint96 currentLeaderOffer,
            uint96 incrementBps
        );

    /// @notice calculates the minimum eth that must be sent with a offer call
    /// @dev returns 0 if no offer can be made for this oken
    /// @param buyer -> the token to be offerd to
    /// @param seller -> the address of the user who will be delegating
    /// @param itemId -> the address of the user who will be delegating
    /// @return canOffer -> instead of reverting this function will return false
    /// @return nextMinUserOffer -> the minimum value that must be sent with a offer call
    /// @return currentUserOffer ->
    function check(
        uint24 buyer,
        uint24 seller,
        uint16 itemId
    )
        external
        view
        returns (
            bool canOffer,
            uint96 nextMinUserOffer,
            uint96 currentUserOffer,
            uint96 currentLeaderOffer,
            uint96 incrementBps,
            bool mustClaimBuyer,
            bool mustOfferOnSeller
        );

    function vfo(address sender, uint24 tokenId) external view returns (uint96 res);

    function vfo(
        uint24 buyer,
        uint24 seller,
        uint16 itemId
    ) external view returns (uint96 res);

    // function tloop() external view returns (bytes memory);

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface INuggftV1Loan {
    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                EVENTS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    event Loan(uint24 indexed tokenId, bytes32 agency);

    event Rebalance(uint24 indexed tokenId, bytes32 agency);

    event Liquidate(uint24 indexed tokenId, bytes32 agency);

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            STATE CHANGING
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    function rebalance(uint24[] calldata tokenIds) external payable;

    function loan(uint24[] calldata tokenIds) external;

    function liquidate(uint24 tokenId) external payable;

    /*━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            VIEW FUNCTIONS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━*/

    /// @notice for a nugg's active loan: calculates the current min eth a user must send to liquidate or rebalance
    /// @dev contract     ->
    /// @param tokenId    -> the token who's current loan to check
    /// @return isLoaned  -> indicating if the token is loaned
    /// @return account   -> indicating if the token is loaned
    /// @return prin      -> the current amount loaned out, plus the final rebalance fee
    /// @return fee       -> the fee a user must pay to rebalance (and extend) the loan on their nugg
    /// @return earn      -> the amount of eth the minSharePrice has increased since loan was last rebalanced
    /// @return expire    -> the epoch the loan becomes insolvent
    function debt(uint24 tokenId)
        external
        view
        returns (
            bool isLoaned,
            address account,
            uint96 prin,
            uint96 fee,
            uint96 earn,
            uint24 expire
        );

    /// @notice "Values For Liquadation"
    /// @dev used to tell user how much eth to send for liquidate
    function vfl(uint24[] calldata tokenIds) external view returns (uint96[] memory res);

    /// @notice "Values For Rebalance"
    /// @dev used to tell user how much eth to send for rebalance
    function vfr(uint24[] calldata tokenIds) external view returns (uint96[] memory res);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface INuggftV1Epoch {
    function epoch() external view returns (uint24 res);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface INuggftV1Trust {
    event TrustUpdated(address indexed user, bool trust);

    function setIsTrusted(address user, bool trust) external;

    function isTrusted(address user) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface INuggftV1ItemSwap {
    event OfferItem(uint24 indexed sellingTokenId, uint16 indexed itemId, bytes32 agency, bytes32 stake);

    event ClaimItem(uint24 indexed sellingTokenId, uint16 indexed itemId, uint24 indexed buyerTokenId, bytes32 proof);

    event SellItem(uint24 indexed sellingTokenId, uint16 indexed itemId, bytes32 agency, bytes32 proof);

    function offer(
        uint24 buyerTokenId,
        uint24 sellerTokenId,
        uint16 itemId
    ) external payable;

    function sell(
        uint24 sellerTokenId,
        uint16 itemid,
        uint96 floor
    ) external;
}
//  SellItem(uint24,uint16,bytes32,bytes32);
//     OfferItem(uint24,uint16, bytes32,bytes32);
//  ClaimItem(uint24,uint16,uint24,bytes32);

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {IDotnuggV1} from "dotnugg-v1-core/IDotnuggV1.sol";

interface INuggftV1Globals {
    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    event Genesis(uint256 blocknum, uint32 interval, uint24 offset, uint8 intervalOffset, uint24 early, address dotnugg, address xnuggftv1, bytes32 stake);

    function genesis() external view returns (uint256 res);

    function stake() external view returns (uint256 res);

    function agency(uint24 tokenId) external view returns (uint256 res);

    function offers(uint24 tokenId, address account) external view returns (uint256 value);

    function itemAgency(uint24 sellingTokenId, uint16 itemId) external view returns (uint256 res);

    function itemOffers(
        uint24 buyingTokenid,
        uint24 sellingTokenId,
        uint16 itemId
    ) external view returns (uint256 res);

    function lastItemSwap(uint16 itemId) external view returns (uint256 res);

    function proof(uint24 tokenId) external view returns (uint256 res);

    function migrator() external view returns (address res);

    function early() external view returns (uint24 res);

    function dotnuggv1() external view returns (IDotnuggV1);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {INuggftV1Swap} from "../interfaces/nuggftv1/INuggftV1Swap.sol";
import {INuggftV1ItemSwap} from "../interfaces/nuggftv1/INuggftV1ItemSwap.sol";

import {NuggftV1Stake} from "./NuggftV1Stake.sol";
import {DotnuggV1Lib} from "dotnugg-v1-core/DotnuggV1Lib.sol";

/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @notice mechanism for trading of nuggs between users (and items between nuggs)
/// @dev Explain to a developer any extra details
abstract contract NuggftV1Swap is INuggftV1ItemSwap, INuggftV1Swap, NuggftV1Stake {
	/// @inheritdoc INuggftV1Swap
	function offer(uint24 tokenId) public payable override {
		_offer(tokenId, msg.value);
	}

	/// @inheritdoc INuggftV1ItemSwap
	function offer(
		uint24 buyingTokenId,
		uint24 sellingTokenId,
		uint16 itemId
	) external payable override {
		_offer(buyingTokenId, sellingTokenId, itemId, msg.value);
	}

	/// @inheritdoc INuggftV1Swap
	function offer(
		uint24 buyingTokenId,
		uint24 sellingTokenId,
		uint16 itemId,
		uint96 offerValue1,
		uint96 offerValue2
	) external payable {
		_repanic(offerValue1 + offerValue2 == msg.value, Error__0xB1__InvalidMulticallValue);

		// claim a nugg
		if (agency[buyingTokenId] >> 254 == 0x3) {
			uint24[] memory a = new uint24[](1);
			a[0] = buyingTokenId;

			address[] memory b = new address[](1);
			b[0] = msg.sender;

			this.claim(a, b, new uint24[](1), new uint16[](1));
		}

		// offer on a nugg
		if (offerValue1 > 0) premint(sellingTokenId, offerValue1);

		// offer on an item
		_offer(buyingTokenId, sellingTokenId, itemId, offerValue2);
	}

	function _offer(
		uint256 buyingTokenId,
		uint256 sellingTokenId,
		uint256 itemId,
		uint256 value
	) internal {
		_offer((buyingTokenId << 40) | (itemId << 24) | sellingTokenId, value);
	}

	function _offer(uint256 tokenId, uint256 value) internal {
		uint256 agency__sptr;
		uint256 agency__cache;

		uint256 active = epoch();

		address sender;
		uint256 offersSlot;

		bool isItem;

		assembly {
			function juke(x, L, R) -> b {
				b := shr(R, shl(L, x))
			}

			function panic(code) {
				mstore(0x00, Revert__Sig)
				mstore8(31, code)
				revert(27, 0x5)
			}

			mstore(0x20, agency.slot)

			isItem := gt(tokenId, 0xffffff)

			switch isItem
			case 1 {
				sender := shr(40, tokenId)

				tokenId := and(tokenId, 0xffffffffff)

				mstore(0x00, sender)

				let buyerTokenAgency := sload(keccak256(0x00, 0x40))

				// ensure the caller is the agent
				if iszero(eq(juke(buyerTokenAgency, 96, 96), caller())) {
					panic(Error__0xA2__NotItemAgent)
				}

				let flag := shr(254, buyerTokenAgency)

				// ensure the caller is really the agent
				if and(eq(flag, 0x3), iszero(iszero(juke(buyerTokenAgency, 2, 232)))) {
					panic(Error__0xA3__NotItemAuthorizedAgent)
				}

				mstore(0x20, _itemAgency.slot)

				offersSlot := _itemOffers.slot
			}
			default {
				sender := caller()

				offersSlot := _offers.slot
			}

			mstore(0x00, tokenId)

			agency__sptr := keccak256(0x00, 0x40)
			agency__cache := sload(agency__sptr)
		}

		// check to see if this nugg needs to be minted
		if (active == tokenId && agency__cache == 0) {
			// [Offer:Mint]

			(uint256 _agency, uint256 _proof) = mint(uint24(tokenId), calculateSeed(uint24(active)), uint24(active), uint96(value), msg.sender);

			addStakedShare(value);

			// prettier-ignore
			assembly {

                // log the updated agency
                mstore(0x00, _agency)
                mstore(0x20, _proof)

                log2( // -------------------------------------------------------
                    /* param #1: agency  */ 0x00, /* [ agency[tokenId]    ]     0x20,
                       param #2: proof      0x20,    [ proof[tokenId]     ]     0x40,
                       param #3: proof      0x40,    [ stake              ]  */ 0x60,
                    /* topic #1: sig     */ Event__OfferMint,
                    /* topic #2: tokenId */ tokenId
                ) // ===========================================================
            }

			return;
		} else if (!isItem && agency__cache == 0) {
			premint(uint24(tokenId), value);
			return;
		}

		// prettier-ignore
		assembly {
            function juke(x, L, R) -> b {
                b := shr(R, shl(L, x))
            }

            function panic(code) {
                mstore(0x00, Revert__Sig)
                mstore8(31, code)
                revert(27, 0x5)
            }

            // ensure that the agency flag is "SWAP" (0x03)
            if iszero(eq(shr(254, agency__cache), 0x03)) {
                panic(Error__0xA0__NotSwapping)
            }

            /////////////////////////////////////////////////////////////////////

            mstore(0x20, offersSlot)


            mstore(0x20, keccak256( // =================================
                0x00, /* [ tokenId        )    0x20
                0x20     [ offers[X].slot ) */ 0x40
            ))// =======================================================

            mstore(0x00, sender)

             offersSlot := keccak256( // ===========================
                0x00, /* [ msg.sender     )    0x20
                0x20     [ offers[X].slot ) */ 0x40
            )// ========================================================

            /////////////////////////////////////////////////////////////////////

            let agency__addr  := juke(agency__cache, 96, 96)

            let agency__epoch := juke(agency__cache, 2, 232)

            // we assume offer__cache is same as agency__cache
            // this will only be the case for the leader
            let offer__cache := agency__cache

            // check to see if msg.sender is the leader
            if iszero(eq(sender, agency__addr)) {
                // if not, we update offer__cache
                offer__cache := sload(offersSlot)
            }

            // check to see if user has offered by checking if cache != 0
            if iszero(iszero(offer__cache)) {
                // check to see if the epoch from offer__cache has expired
                // this accomplishes two important goals:
                // 1. forces user to claim previous swap before acting on this one
                // 2. prevents owner from offering on their own swap before someone else has
                if lt(juke(offer__cache, 2, 232), active) {
                    panic(Error__0x99__InvalidEpoch)
                }
            }

            /////////////////////////////////////////////////////////////////////

            // check to see if the swap's epoch is 0, make required updates

            switch iszero(agency__epoch)
            // if so, we know this swap has not yet been offered on
            case 1 { // [Offer:Commit]

                let nextEpoch := add(active, SALE_LEN)

                // update the epoch to begin auction
                agency__cache := xor( // =====================================
                    /* start */  agency__cache,
                    // we know that the epoch is 0
                    // -------------------------------------------------------
                        /* address       0,    [                 ) 160 */
                        /* eth         160,    [                 ) 230 */
                   shl( /* epoch    */ 230, /* [ */ nextEpoch /* ) 254 */ )
                        /* flag        254,    [                 ) 256 */
                ) // ==========================================================

                if isItem {
                    // check to make sure there is not a swap
                    // this blocks more than one swap of a particular item of ending in the same epoch

                    mstore(0x80, shr(24, tokenId))
                    mstore(0xA0, lastItemSwap.slot)

                    mstore(0x80, keccak256(0x80, 0x40))

                    let val := sload(mload(0x80))

                    if eq(nextEpoch, and(val, 0xffffff)) {
                        panic(Error__0xAC__MustFinalizeOtherItemSwap)
                    }

					if eq(nextEpoch, add(and(val, 0xffffff), 1)) {
                        panic(Error__0xB4__MustFinalizeOtherItemSwapFromThisEpoch)
                    }

                    val := shl(48, val)

                    val := or(val, shl(24, and(tokenId, 0xffffff)))

                    // since epoch 1 cant happen (unless OFFSET is 0)
                    sstore(mload(0x80), or(val, nextEpoch))

                }

            }
            default { // [Offer:Carry]
                // otherwise we validate the epoch to ensure the swap is still active
                // baisically, "is the auction's epoch in the past?"
                if lt(agency__epoch, active) {
                    // - if yes, we revert
                    panic(Error__0xA4__ExpiredEpoch)
                }
            }

            /////////////////////////////////////////////////////////////////////

            // parse last offer value
           let last := juke(agency__cache, 26, 186)

            // store callvalue formatted in .1 gwei for caculation of total offer
            let next := div(value, LOSS)

            // parse and caculate next offer value
            next := add(juke(offer__cache, 26, 186), next)

            if iszero(gt(next, 100)) {
                panic(Error__0x68__OfferLowerThanLOSS)
            }

            let increment := sub(INTERVAL, mod(number(), INTERVAL))

            // 10 min 50% increment jump
            switch and(eq(agency__epoch, active), lt(increment, 45))
            case 1 {
                increment := mul(div(increment, 5), 5)
                increment := add(mul(sub(50, increment), 100), BASE_BPS)
            }
            default {
                increment := INCREMENT_BPS
            }

            // ensure next offer includes at least a 5-50% increment
            if gt(div(mul(last, increment), BASE_BPS), next) {
                panic(Error__0x72__IncrementTooLow)
            }
            // convert next into the increment
            next := sub(next, last)

            switch eq(agency__addr, address())
            case 1 {
                last := mul(add(next, last), LOSS)
                // TODO make sure no overflow issue
                if lt(last, value) {
                    if gt(sub(value, last),LOSS) {
                        panic(Error__0xB2__UnexpectedIncrement)
                    }
                    last := add(last, sub(value, last))
                }
            }
            default {
                // convert last into increment * LOSS for staking
                last := mul(next, LOSS)
            }

            /////////////////////////////////////////////////////////////////////

            // we update the previous user's "offer" so we
            //  1. know how much to repay them
            //  2. know how much they have already bid

            mstore(0x00, agency__addr)

            // calculate the previous leaders offer storage pointer and set it to agency__cache
            sstore( keccak256( //-------------------------------------------------
                0x00, /* [ address(prev leader)                  ]    0x20
                0x20     [ offers[X].slot                        ] */ 0x40
            ), agency__cache) // ---------------------------------------------

            // after we save the prevous state, we clear the previous leader from agency cache
            agency__cache := shl(160, shr(160, agency__cache))

            /////////////////////////////////////////////////////////////////////

            agency__cache := add(xor(// ========================================
                /* start  */ agency__cache,
                // -------------------------------------------------------------
                    /* address      0     [ */ sender /* ) 160 */ ),
               shl( /* eth     */ 160, /* [ */ next   /* ) 230 */ )
                    /* epoch      230     [              ) 254 */
                    /* flag       254     [              ) 256 */
            ) // ===============================================================

            sstore(agency__sptr, agency__cache)

            sstore(offersSlot, agency__cache)

            mstore(0x00, agency__cache)

            next := div(last, PROTOCOL_FEE_FRAC)

            last := add(sload(stake.slot), or(shl(96, sub(last, next)), next))

            sstore(stake.slot, last)

            mstore(0x20, last)

            switch isItem
            case 1 {
                log3( // =======================================================
                    /* param #1: agency   bytes32 */ 0x00, /* [ _itemAgency[tokenId][itemId] )   0x20
                       param #2: stake    bytes32    0x20     [ stake                       ) */ 0x40,
                    // ---------------------------------------------------------
                    /* topic #1: sig              */ Event__OfferItem,
                    /* topic #2: sellerId uint24  */ and(tokenId, 0xffffff),
                    /* topic #3: itemId   uint16  */ shr(24, tokenId)
                ) // ===========================================================
            }
            default {
                log2( // =======================================================
                    /* param #1: agency  bytes32 */ 0x00, /* [ agency[tokenId] )    0x20
                       param #2: stake   bytes32    0x20     [ stake           ) */ 0x40,
                    // ---------------------------------------------------------
                    /* topic #1: sig             */ Event__Offer,
                    /* topic #2: tokenId uint24 */ tokenId
                ) // ===========================================================
            }
        }
	}

	function premint(uint24 tokenId, uint256 value) internal {
		_repanic(agency[tokenId] == 0, Error__0x65__TokenNotMintable);

		(uint24 first, uint24 last) = premintTokens();

		_repanic(tokenId >= first && tokenId <= last, Error__0x65__TokenNotMintable);

		(, uint256 _proof) = mint(tokenId, calculateEarlySeed(tokenId), 0, 0, address(this));

		uint16 item = uint16(_proof >> 0x90);

		this.sell(tokenId, item, STARTING_PRICE);

		(uint96 _msp, , , , ) = minSharePriceBreakdown(stake);

		this.sell(tokenId, _msp);

		_offer(tokenId, value);

		delete _offers[tokenId][address(this)];
	}

	function mint(
		uint24 tokenId,
		uint256 seed,
		uint24 epoch,
		uint96 value,
		address to
	) internal returns (uint256 _agency, uint256 _proof) {
		uint256 ptrA;
		uint256 ptrB;

		_proof = initFromSeed(seed);

		address itemHolder = address(xnuggftv1);

		proof[tokenId] = _proof;

		// @solidity memory-safe-assembly
		assembly {
			mstore(0x00, tokenId)
			mstore(0x20, agency.slot)

			ptrA := mload(0x40)
			ptrB := mload(0x40)

			// ============================================================
			// agency__sptr is the storage value that solidity would compute
			// + if you used "agency[tokenId]"
			// prettier-ignore
			let agency__sptr := keccak256( // =============================
                0x00, /* [ tokenId                               ]    0x20
                0x20     [ agency.slot                           ] */ 0x40
            ) // ==========================================================

			if iszero(iszero(sload(agency__sptr))) {
				mstore(0x00, Revert__Sig)
				mstore8(31, Error__0x80__TokenDoesExist)
				revert(27, 0x5)
			}

			// prettier-ignore
			_agency := xor(xor(xor( // =============================
                          /* addr     0       [ */ to,              /* ] 160 */
                    shl(  /* eth   */ 160, /* [ */ div(value, LOSS) /* ] 230 */ )),
                    shl(  /* epoch */ 230, /* [ */ epoch                 /* ] 254 */ )),
                    shl(  /* flag  */ 254, /* [ */ 0x03                   /* ] 255 */ )
                ) // ==========================================================

			sstore(agency__sptr, _agency)

			// mstore(0x00, value)
			mstore(0x20, _proof)
			// mstore(0x60, _agency)

			log4(0x00, 0x00, Event__Transfer, 0, address(), tokenId)

			mstore(0x00, Function__transferBatch)
			mstore(0x40, 0x00)
			mstore(0x60, address())

			// TODO make sure this is the right way to do this
			if iszero(call(gas(), itemHolder, 0x00, 0x1C, 0x64, 0x00, 0x00)) {
				mstore(0x00, Revert__Sig)
				mstore8(31, Error__0xAE__FailedCallToItemsHolder)
				revert(27, 0x5)
			}

			mstore(0x40, ptrA)
			mstore(0x40, ptrB)
		}
	}

	/// @inheritdoc INuggftV1Swap
	function claim(
		uint24[] calldata tokenIds,
		address[] calldata accounts,
		uint24[] calldata buyingTokenIds,
		uint16[] calldata itemIds
	) public override {
		uint256 active = epoch();

		address itemsHolder = address(xnuggftv1);

		// prettier-ignore
		assembly {

            mstore(0x200, itemsHolder)
            pop(itemsHolder)

            function panic(code) {
                mstore(0x00, Revert__Sig)
                mstore8(31, code)
                revert(27, 0x5)
            }

            function juke(x, L, R) -> b {
                b := shr(R, shl(L, x))
            }

            // extract length of tokenIds array from calldata
            let len := calldataload(sub(tokenIds.offset, 0x20))

            // ensure arrays the same length
            if iszero(eq(len, calldataload(sub(accounts.offset, 0x20)))) {
                panic(Error__0x76__InvalidArrayLengths)
            }

            // ensure arrays the same length
            if iszero(eq(len, calldataload(sub(itemIds.offset, 0x20)))) {
                panic(Error__0x76__InvalidArrayLengths)
            }

            if iszero(eq(len, calldataload(sub(buyingTokenIds.offset, 0x20)))) {
                panic(Error__0x76__InvalidArrayLengths)
            }

            let acc := 0

            /*========= memory ============
              0x00: tokenId
              0x20: agency.slot
              [keccak]: agency[tokenId].slot = "agency__sptr"
              --------------------------
              0x40: tokenId
              0x60: _offers.slot
              [keccak]: offers[tokenId].slot = "offer__sptr"
              --------------------------
              0x80: offerer
              0xA0: offers[tokenId].slot
              [keccak]: _itemOffers[tokenId][offerer].slot = "offer__sptr"
              --------------------------
              0xC0: itemId || sellingTokenId
              0xE0: _itemAgency.slot
              [keccak]: _itemAgency[itemId || sellingTokenId].slot = "agency__sptr"
              --------------------------
              0x100: itemId|sellingTokenId
              0x120: _itemOffers.slot
              [keccak]: _itemOffers[itemId||sellingTokenId].slot
            ==============================*/

            // store common slot for agency in memory
            mstore(0x20, agency.slot)

            // store common slot for offers in memory
            mstore(0x60, _offers.slot)

            // store common slot for agency in memory
            mstore(0xE0, _itemAgency.slot)

            // store common slot for offers in memory
            mstore(0x120, _itemOffers.slot)

            // store common slot for proof in memory
            mstore(0x160, proof.slot)

            for { let i := 0 } lt(i, len) { i := add(i, 1) } {

                let isItem

                 // accounts[i]
                let offerer := calldataload(add(accounts.offset, shl(5, i)))

                // tokenIds[i]
                let tokenId := calldataload(add(tokenIds.offset, shl(5, i)))

                if iszero(offerer) {
                    offerer := calldataload(add(buyingTokenIds.offset, shl(5, i)))
                    isItem := 1
                    tokenId := or(tokenId, shl(24, calldataload(add(itemIds.offset, shl(5, i)))))
                }

                //
                let trusted := offerer

                let mptroffset := 0

                if isItem {

                    // if this claim is for an item aucton we need to check the nugg that is
                    // + claiming and set their owner as the "trusted"

                    mstore(0x00, offerer)

                    let offerer__agency := sload(keccak256(0x00, 0x40))

                    trusted := juke(offerer__agency, 96, 96)

                    mptroffset := 0xC0
                }

                // calculate agency.slot storeage ptr
                mstore(mptroffset, tokenId)

                let agency__sptr := keccak256(mptroffset, 0x40)

                // load agency value from storage
                let agency__cache := sload(agency__sptr)

                // calculate _offers.slot storage pointer
                mstore(add(mptroffset, 0x40), tokenId)
                let offer__sptr := keccak256(add(mptroffset, 0x40), 0x40)

                // calculate offers[tokenId].slot storage pointer
                mstore(0x80, offerer)
                mstore(0xA0, offer__sptr)
                offer__sptr := keccak256(0x80, 0x40)


                // check if the offerer is the current agent ()
                switch eq(offerer, juke(agency__cache, 96, 96))
                case 1 {
                    let agency__epoch := juke(agency__cache, 2, 232)

                    // ensure that the agency flag is "SWAP" (0x03)
                    // importantly, this only needs to be done for "winning" claims,
                    // + otherwise
                    if iszero(eq(shr(254, agency__cache), 0x03)) {
                        panic(Error__0xA0__NotSwapping)
                    }

                    // check to make sure the user is the seller or the swap is over
                    // we know a user is a seller if the epoch is still 0
                    // we know a swap is over if the active epoch is greater than the swaps epoch
                    if iszero(or(iszero(agency__epoch), gt(active, agency__epoch))) {
                        panic(Error__0x67__WinningClaimTooEarly)
                    }

                    switch isItem
                    case 1 {
                        sstore(agency__sptr, 0)

                        mstore(0x140, offerer)

                        let proof__sptr := keccak256(0x140, 0x40)

                        let _proof := sload(proof__sptr)

                        // prettier-ignore
                        for { let j := 8 } lt(j, 16) { j := add(j, 1) } {
                            if iszero(and(shr(mul(j, 16), _proof), 0xffff)) {
                                let tmp := shr(24, tokenId)
                                _proof := xor(_proof, shl(mul(j, 16), tmp))
                                break
                            }
                        }

                        sstore(proof__sptr, _proof)

                        mstore(0x220, Function__transferSingle)
                        mstore(0x240, shr(24, tokenId))
                        mstore(0x260, address())
                        mstore(0x280, trusted)

                        if iszero(call(gas(), mload(0x200), 0x00, 0x23C, 0x64, 0x00, 0x00)) {
                            panic(Error__0xAE__FailedCallToItemsHolder)
                         }

                        mstore(0x1A0, _proof)
                    }
                    default {

                        mstore(0x140, tokenId)

                        let _proof := sload(keccak256(0x140, 0x40))

                        mstore(0x220, Function__transferBatch)
                        mstore(0x240, _proof)
                        mstore(0x260, address())
                        mstore(0x280, trusted)

                        // this call can only fail if not enough gas is passed
                        if iszero(call(gas(), mload(0x200), 0x00, 0x23C, 0x64, 0x00, 0x00)) {
                            panic(Error__0xAE__FailedCallToItemsHolder)
                        }

                        // save the updated agency
                        sstore(agency__sptr, xor( // =============================
                                /* addr     0       [ */ offerer, /*  ] 160 */
                                /* eth      160,    [    next         ] 230 */
                                /* epoch    230,    [    active       ] 254 */
                           shl( /* flag  */ 254, /* [ */ 0x01      /* ] 255 */ ))
                        ) // ==========================================================

                        // "transfer" token to the new owner
                        log4( // =======================================================
                            /* param #0:n/a  */ 0x00, /* [ n/a ] */  0x00,
                            /* topic #1:sig  */ Event__Transfer,
                            /* topic #2:from */ address(),
                            /* topic #3:to   */ offerer,
                            /* topic #4:id   */ tokenId
                        ) // ===========================================================
                    }
                }
                default {
                    if iszero(eq(caller(), trusted)) {
                        panic(Error__0x74__Untrusted)
                    }

                    let offer__cache := sload(offer__sptr)

                    // ensure this user has an offer to claim
                    if iszero(offer__cache) {
                        panic(Error__0xA5__NoOffer)
                    }

                    // accumulate and send value at once at end
                    // to save on gas for most common use case
                    acc := add(acc, juke(offer__cache, 26, 186))
                }

                // delete offer before we potentially send value
                sstore(offer__sptr, 0)

                switch isItem
                case 1 {
                    log4(0x1A0, 0x20, Event__ClaimItem, and(tokenId, 0xffffff), shr(24, tokenId), offerer)
                    mstore(0x1A0, 0x00)
                }
                default {
                    log3(0x00, 0x00, Event__Claim, tokenId, offerer)
                }
            }

            // skip sending value if amount to send is 0
            if iszero(iszero(acc)) {

                acc := mul(acc, LOSS)

                // we could add a whole bunch of logic all over to ensure that contracts cant use this, but
                // lets just keep it simple - if you own you nugg with a contract, you have no way to make any
                // eth on it.

                // since a meaninful claim can only be made the epoch after a swap is over, it is at least 1 block
                // later. So, if a contract that has offered will not be in creation when it hits here,
                // so our call to extcodesize is sufficcitent to check if caller is a contract or not

                // send accumulated value * LOSS to msg.sender
                switch iszero(extcodesize(caller()))
                case 1 {
                    pop(call(gas(), caller(), acc, 0, 0, 0, 0))
                }
                default {
                    // if someone really ends up here, just donate the eth
                    let pro := div(acc, PROTOCOL_FEE_FRAC)

                    let cache := add(sload(stake.slot), or(shl(96, sub(acc, pro)), pro))

                    sstore(stake.slot, cache)

                    mstore(0x00, cache)

                    log1(0x00, 0x20, Event__Stake)
                }
            }
        }
	}

	/// @inheritdoc INuggftV1ItemSwap
	function sell(
		uint24 sellingTokenId,
		uint16 itemId,
		uint96 floor
	) external override {
		_sell((uint40(itemId) << 24) | uint40(sellingTokenId), floor);
	}

	/// @inheritdoc INuggftV1Swap
	function sell(uint24 tokenId, uint96 floor) external override {
		_sell(tokenId, floor);
	}

	function _sell(uint40 tokenId, uint96 floor) private {
		address itemHolder = address(xnuggftv1);

		assembly {
			function panic(code) {
				mstore(0x00, Revert__Sig)
				mstore8(31, code)
				revert(27, 0x5)
			}

			function juke(x, L, R) -> b {
				b := shr(R, shl(L, x))
			}

			let mptr := mload(0x40)

			mstore(0x20, agency.slot)

			let sender := caller()

			let isItem := gt(tokenId, 0xffffff)

			if isItem {
				sender := and(tokenId, 0xffffff)

				mstore(0x00, sender)

				let buyerTokenAgency := sload(keccak256(0x00, 0x40))

				// ensure the caller is the agent
				if iszero(eq(juke(buyerTokenAgency, 96, 96), caller())) {
					panic(Error__0xA2__NotItemAgent)
				}

				let flag := shr(254, buyerTokenAgency)

				// ensure the caller is really the agent
				// aka makes sure they are not in the middle of a swap
				if and(eq(flag, 0x3), iszero(iszero(juke(buyerTokenAgency, 2, 232)))) {
					panic(Error__0xA3__NotItemAuthorizedAgent)
				}

				mstore(0x20, _itemAgency.slot)
			}

			mstore(0x00, tokenId)

			let agency__sptr := keccak256(0x00, 0x40)

			let agency__cache := sload(agency__sptr)

			// update agency to reflect the new sale

			switch isItem
			case 1 {
				if iszero(iszero(agency__cache)) {
					// panic(Error__0x97__ItemAgencyAlreadySet)

					if iszero(eq(juke(agency__cache, 96, 96), sender)) {
						panic(Error__0xB3__NuggIsNotItemAgent)
					}

					agency__cache := xor(xor(shl(254, 0x03), shl(160, div(floor, LOSS))), sender)

					sstore(agency__sptr, agency__cache)

					mstore(0x00, agency__cache)
					mstore(0x20, 0x00)

					log3(0x00, 0x40, Event__SellItem, and(tokenId, 0xffffff), shr(24, tokenId))

					// panic(Error__0x97__ItemAgencyAlreadySet)

					return(0, 0)
				}

				mstore(0x00, sender)

				// store common slot for offers in memory
				mstore(0x20, proof.slot)

				let proof__sptr := keccak256(0x00, 0x40)

				let _proof := sload(proof__sptr)

				let id := shr(24, tokenId)

				// start at 1 to jump over the visibles
				let j := 1

				// prettier-ignore
				for { } lt(j, 16) { j := add(j, 1) } {
                    if eq(and(shr(mul(j, 16), _proof), 0xffff), id) {
                        _proof := and(_proof, not(shl(mul(j, 16), 0xffff)))
                        break
                    }
                }

				if eq(j, 16) {
					panic(Error__0xA9__ProofDoesNotHaveItem)
				}

				sstore(proof__sptr, _proof)

				// ==== agency[tokenId] =====
				//   flag  = SWAP(0x03)
				//   epoch = 0
				//   eth   = seller decided floor / .1 gwei
				//   addr  = seller
				// ==========================

				agency__cache := xor(xor(shl(254, 0x03), shl(160, div(floor, LOSS))), sender)

				sstore(agency__sptr, agency__cache)

				// log2 with 'Sell(uint24,bytes32)' topic
				mstore(0x00, agency__cache)
				mstore(0x20, _proof)

				log3(0x00, 0x40, Event__SellItem, and(tokenId, 0xffffff), shr(24, tokenId))

				mstore(0x00, Function__transferSingle)
				mstore(0x20, shr(24, tokenId))
				mstore(0x40, caller())
				mstore(0x60, address())

				if iszero(call(gas(), itemHolder, 0x00, 0x1C, 0x64, 0x00, 0x00)) {
					panic(Error__0xAE__FailedCallToItemsHolder)
				}
			}
			default {
				// ensure the caller is the agent
				if iszero(eq(shr(96, shl(96, agency__cache)), caller())) {
					panic(Error__0xA1__NotAgent)
				}

				let flag := shr(254, agency__cache)

				let isWaitingForOffer := and(eq(flag, 0x3), iszero(juke(agency__cache, 2, 232)))

				// ensure the agent is the owner
				if iszero(isWaitingForOffer) {
					// ensure the agent is the owner
					if iszero(eq(flag, 0x1)) {
						panic(Error__0x77__NotOwner)
					}
				}

				let stake__cache := sload(stake.slot)

				let activeEps := div(juke(stake__cache, 64, 160), shr(192, stake__cache))

				if lt(floor, activeEps) {
					panic(Error__0x70__FloorTooLow)
				}

				// ==== agency[tokenId] =====
				//   flag  = SWAP(0x03)
				//   epoch = 0
				//   eth   = seller decided floor / .1 gwei
				//   addr  = seller
				// ==========================

				agency__cache := xor(xor(shl(254, 0x03), shl(160, div(floor, LOSS))), caller())

				sstore(agency__sptr, agency__cache)

				// log2 with 'Sell(uint24,bytes32)' topic
				mstore(0x00, agency__cache)

				log2(0x00, 0x20, Event__Sell, tokenId)

				if iszero(isWaitingForOffer) {
					// prettier-ignore
					log4( // =======================================================
                        /* param 0: n/a  */ 0x00, 0x00,
                        /* topic 1: sig  */ Event__Transfer,
                        /* topic 2: from */ caller(),
                        /* topic 3: to   */ address(),
                        /* topic 4: id   */ tokenId
                    ) // ===========================================================

					mstore(0x00, tokenId)
					mstore(0x20, proof.slot)

					let _proof := sload(keccak256(0x00, 0x40))

					mstore(0x00, Function__transferBatch)
					mstore(0x20, _proof)
					mstore(0x40, address())
					mstore(0x60, caller())

					if iszero(call(gas(), itemHolder, 0x00, 0x1C, 0x64, 0x00, 0x00)) {
						panic(Error__0xAE__FailedCallToItemsHolder)
					}
				}
			}
		}
	}

	// @inheritdoc INuggftV1Swap
	function vfo(address sender, uint24 tokenId) public view override returns (uint96 res) {
		(bool canOffer, uint96 next, uint96 current, , ) = check(sender, tokenId);

		if (canOffer) res = next - current;
	}

	// @inheritdoc INuggftV1Swap
	function check(address sender, uint24 tokenId)
		public
		view
		override
		returns (
			bool canOffer,
			uint96 next,
			uint96 currentUserOffer,
			uint96 currentLeaderOffer,
			uint96 incrementBps
		)
	{
		canOffer = true;

		uint24 activeEpoch = epoch();

		(uint96 _msp, , , , ) = minSharePriceBreakdown(stake);

		uint24 _early = early;

		incrementBps = INCREMENT_BPS;

		assembly {
			function juke(x, L, R) -> b {
				b := shr(R, shl(L, x))
			}

			mstore(0x00, tokenId)
			mstore(0x20, agency.slot)

			let swapData := sload(keccak256(0x00, 0x40))

			let offerData := swapData

			let isLeader := eq(juke(swapData, 96, 96), sender)

			if iszero(isLeader) {
				mstore(0x20, _offers.slot)
				mstore(0x20, keccak256(0x00, 0x40))
				mstore(0x00, sender)
				offerData := sload(keccak256(0x00, 0x40))
			}

			switch iszero(swapData)
			case 1 {
				switch eq(tokenId, activeEpoch)
				case 1 {
					currentLeaderOffer := _msp
				}
				default {
					if iszero(and(iszero(lt(tokenId, MINT_OFFSET)), lt(tokenId, add(MINT_OFFSET, _early)))) {
						mstore(0x00, 0x00)
						mstore(0x20, 0x00)
						mstore(0x40, 0x00)
						mstore(0x60, 0x00)
						return(0x00, 0x80)
					}

					currentLeaderOffer := _msp
				}
			}
			default {
				let swapEpoch := juke(swapData, 2, 232)

				if and(isLeader, iszero(swapEpoch)) {
					canOffer := 0
				}

				if eq(swapEpoch, activeEpoch) {
					let remain := sub(INTERVAL, mod(number(), INTERVAL))

					if lt(remain, 45) {
						remain := mul(div(remain, 5), 5)
						incrementBps := add(mul(sub(50, remain), 100), BASE_BPS)
					}
				}

				currentUserOffer := mul(juke(offerData, 26, 186), LOSS)

				currentLeaderOffer := mul(juke(swapData, 26, 186), LOSS)
			}

			next := currentLeaderOffer

			if lt(next, STARTING_PRICE) {
				next := STARTING_PRICE
				incrementBps := INCREMENT_BPS
			}

			// add at the end to round up
			next := div(mul(next, incrementBps), BASE_BPS)

			if iszero(iszero(mod(next, LOSS))) {
				next := add(mul(div(next, LOSS), LOSS), LOSS)
			}
		}
	}

	function validAgency(uint256 _agency, uint24 epoch) public pure returns (bool) {
		return _agency >> 254 == 0x3 && (uint24(_agency >> 232) >= epoch || uint24(_agency >> 232) == 0);
	}

	function agencyOf(uint24 tokenId) public view override returns (uint256 res) {
		if (tokenId == 0 || (res = agency[tokenId]) != 0) return res;

		(uint24 start, uint24 end) = premintTokens();

		uint24 e;

		if ((tokenId >= start && tokenId <= end) || (e = epoch()) == tokenId) {
			(uint96 _msp, , , , ) = minSharePriceBreakdown(stake);

			res = (0x03 << 254) + (uint256(((_msp / LOSS))) << 160);

			res += uint160(address(this));

			if (e == tokenId) {
				res |= uint256(e) << 230;
			}
		}
	}

	function itemAgencyOf(uint24 seller, uint16 itemId) public view override returns (uint256 res) {
		res = itemAgency(seller, itemId);

		if (res == 0 && agency[seller] == 0 && uint16(proofOf(seller) >> 0x90) == itemId) {
			return (0x03 << 254) + (uint256((STARTING_PRICE / LOSS)) << 160) + uint256(seller);
		}
	}

	function check(
		uint24 buyer,
		uint24 seller,
		uint16 itemId
	)
		public
		view
		override
		returns (
			bool canOffer,
			uint96 next,
			uint96 currentUserOffer,
			uint96 currentLeaderOffer,
			uint96 incrementBps,
			bool mustClaimBuyer,
			bool mustOfferOnSeller
		)
	{
		canOffer = true;

		uint24 activeEpoch = epoch();

		uint256 buyerAgency = agency[buyer];

		if (buyerAgency >> 254 == 0x3) mustClaimBuyer = true;

		uint256 agency__cache = itemAgency(seller, itemId);

		uint256 offerData = agency__cache;

		currentLeaderOffer = STARTING_PRICE;

		if (agency__cache == 0 && agency[seller] == 0 && uint16(proofOf(seller) >> 0x90) == itemId) {
			mustOfferOnSeller = true;

			agency__cache = (0x03 << 254) + (uint256((STARTING_PRICE / LOSS)) << 160) + uint256(seller);
		} else if (buyer != uint24(agency__cache)) {
			offerData = itemOffers(buyer, seller, itemId);
		}

		uint24 agencyEpoch = uint24(agency__cache >> 230);

		if (agencyEpoch == 0 && offerData == agency__cache) canOffer = false;

		currentUserOffer = uint96((offerData << 26) >> 186) * LOSS;

		currentLeaderOffer = uint96((agency__cache << 26) >> 186) * LOSS;

		next = currentLeaderOffer;

		incrementBps = INCREMENT_BPS;

		assembly {
			if eq(agencyEpoch, activeEpoch) {
				let remain := sub(INTERVAL, mod(number(), INTERVAL))

				if lt(remain, 45) {
					remain := mul(div(remain, 5), 5)
					incrementBps := add(mul(sub(50, remain), 100), BASE_BPS)
				}
			}

			if lt(next, STARTING_PRICE) {
				next := STARTING_PRICE
				incrementBps := INCREMENT_BPS
			}

			// add at the end to round up
			next := div(mul(next, incrementBps), BASE_BPS)

			if iszero(iszero(mod(next, LOSS))) {
				next := add(mul(div(next, LOSS), LOSS), LOSS)
			}
		}
	}

	function vfo(
		uint24 buyer,
		uint24 seller,
		uint16 itemId
	) public view override returns (uint96 res) {
		(bool canOffer, uint96 next, uint96 current, , , , ) = check(buyer, seller, itemId);

		if (canOffer) res = next - current;
	}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {IERC1155, IERC165, IERC1155Metadata_URI} from "./interfaces/IERC721.sol";

import {IxNuggftV1} from "./interfaces/nuggftv1/IxNuggftV1.sol";
import {DotnuggV1Lib} from "dotnugg-v1-core/DotnuggV1Lib.sol";
import {IDotnuggV1} from "dotnugg-v1-core/IDotnuggV1.sol";
import {NuggftV1Constants} from "./core/NuggftV1Constants.sol";

import {INuggftV1} from "./interfaces/nuggftv1/INuggftV1.sol";

/// @author nugg.xyz - danny7even and dub6ix - 2022
contract xNuggftV1 is IxNuggftV1 {
	using DotnuggV1Lib for IDotnuggV1;

	INuggftV1 immutable nuggftv1;

	constructor() {
		nuggftv1 = INuggftV1(msg.sender);
	}

	/// @inheritdoc IxNuggftV1
	function imageURI(uint256 tokenId) public view override returns (string memory res) {
		(uint8 feature, uint8 position) = DotnuggV1Lib.parseItemId(tokenId);
		res = nuggftv1.dotnuggv1().exec(feature, position, true);
	}

	/// @inheritdoc IxNuggftV1
	function imageSVG(uint256 tokenId) public view override returns (string memory res) {
		(uint8 feature, uint8 position) = DotnuggV1Lib.parseItemId(tokenId);
		res = nuggftv1.dotnuggv1().exec(feature, position, false);
	}

	function transferBatch(
		uint256 proof,
		address from,
		address to
	) external payable {
		require(msg.sender == address(nuggftv1));

		unchecked {
			uint256 tmp = proof;

			uint256 length = 1;

			while (tmp != 0) if ((tmp >>= 16) & 0xffff != 0) length++;

			uint256[] memory ids = new uint256[](length);
			uint256[] memory values = new uint256[](length);

			ids[0] = proof & 0xffff;
			values[0] = 1;

			while (proof != 0)
				if ((tmp = ((proof >>= 16) & 0xffff)) != 0) {
					ids[--length] = tmp;
					values[length] = 1;
				}

			emit TransferBatch(address(0), from, to, ids, values);
		}
	}

	function transferSingle(
		uint256 itemId,
		address from,
		address to
	) external payable {
		require(msg.sender == address(nuggftv1));
		emit TransferSingle(address(0), from, to, itemId, 1);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return
			interfaceId == 0xd9b67a26 || //
			interfaceId == 0x0e89341c ||
			interfaceId == type(IERC165).interfaceId;
	}

	function name() public pure returns (string memory) {
		return "Nugg Fungible Items V1";
	}

	function symbol() public pure returns (string memory) {
		return "xNUGGFT";
	}

	function features() public pure returns (string[8] memory) {
		return ["base", "eyes", "mouth", "head", "back", "flag", "tail", "hold"];
	}

	function uri(uint256 tokenId) public view virtual override returns (string memory res) {
		// prettier-ignore
		res = string(
            nuggftv1.dotnuggv1().encodeJson(
                abi.encodePacked(
                     '{"name":"',         name(),
                    '","description":"',  DotnuggV1Lib.itemIdToString(uint16(tokenId), features()),
                    '","image":"',        imageURI(tokenId),
                    '}'
                ), true
            )
        );
	}

	function totalSupply() public view returns (uint256 res) {
		for (uint8 i = 0; i < 8; i++) res += featureSupply(i);
	}

	function featureSupply(uint8 feature) public view override returns (uint256 res) {
		res = nuggftv1.dotnuggv1().lengthOf(feature);
	}

	function rarity(uint256 tokenId) public view returns (uint16 res) {
		(uint8 feature, uint8 position) = DotnuggV1Lib.parseItemId(tokenId);
		res = nuggftv1.dotnuggv1().rarity(feature, position);
	}

	function balanceOf(address _owner, uint256 _id) public view override returns (uint256 res) {
		uint24[] memory tokens = nuggftv1.tokensOf(_owner);

		for (uint24 i = 0; i < tokens.length; i++) {
			uint256 proof = nuggftv1.proofOf(tokens[i]);
			do {
				if (uint16(proof) == _id) res++;
				proof >>= 16;
			} while (proof != 0);
		}
	}

	function balanceOfBatch(address[] calldata _owners, uint256[] memory _ids) external view override returns (uint256[] memory) {
		for (uint256 i = 0; i < _owners.length; i++) {
			_ids[i] = balanceOf(_owners[i], _ids[i]);
		}

		return _ids;
	}

	function isApprovedForAll(address, address) external pure override returns (bool) {
		return false;
	}

	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _id,
		uint256 _value,
		bytes calldata _data
	) public {}

	function safeBatchTransferFrom(
		address _from,
		address _to,
		uint256[] calldata _ids,
		uint256[] calldata _values,
		bytes calldata _data
	) external {}

	function setApprovalForAll(address, bool) external pure {
		revert("whut");
	}

	function floop(uint24 tokenId) public view returns (uint16[16] memory arr) {
		return DotnuggV1Lib.decodeProof(nuggftv1.proofOf(tokenId));
	}

	function ploop(uint24 tokenId) public view returns (string memory) {
		return DotnuggV1Lib.props(floop(tokenId), features());
	}

	function iloop() external view override returns (bytes memory res) {
		uint256 ptr;

		res = new bytes(256 * 8);

		assembly {
			ptr := add(res, 32)
		}

		for (uint8 i = 0; i < 8; i++) {
			uint8 len = nuggftv1.dotnuggv1().lengthOf(i) + 1;
			for (uint8 j = 1; j < len; j++) {
				uint16 item = DotnuggV1Lib.encodeItemId(i, j);
				// @solidity memory-safe-assembly
				assembly {
					mstore8(ptr, shr(8, item))
					mstore8(add(ptr, 1), item)
					ptr := add(ptr, 2)
				}
			}
		}

		assembly {
			mstore(res, sub(sub(ptr, res), 32))
		}
	}

	function tloop() external view override returns (bytes memory res) {
		uint24 epoch = nuggftv1.epoch();
		uint256 ptr;

		res = new bytes(24 * 100000);

		assembly {
			ptr := add(res, 32)
		}

		for (uint24 i = 1; i <= epoch; i++)
			if (0 != nuggftv1.agencyOf(i)) {
				// @solidity memory-safe-assembly
				assembly {
					mstore8(ptr, shr(16, i))
					mstore8(add(ptr, 1), shr(8, i))
					mstore8(add(ptr, 2), i)
					ptr := add(ptr, 3)
				}
			}

		(uint24 start, uint24 end) = nuggftv1.premintTokens();

		for (uint24 i = start; i <= end; i++)
			if (0 != nuggftv1.agencyOf(i)) {
				// @solidity memory-safe-assembly
				assembly {
					mstore8(ptr, shr(16, i))
					mstore8(add(ptr, 1), shr(8, i))
					mstore8(add(ptr, 2), i)
					ptr := add(ptr, 3)
				}
			}

		assembly {
			mstore(res, sub(sub(ptr, res), 32))
		}
	}

	function sloop() external view override returns (bytes memory res) {
		unchecked {
			uint24 epoch = nuggftv1.epoch();
			uint256 working;
			uint256 ptr;

			res = new bytes(37 * 10000);

			// @solidity memory-safe-assembly
			assembly {
				ptr := add(res, 32)
			}

			working = nuggftv1.agencyOf(epoch);

			assembly {
				mstore(add(ptr, 5), epoch)
				mstore(ptr, working)
				ptr := add(ptr, 37)
			}

			for (uint24 i = 0; i < epoch; i++) {
				working = nuggftv1.agency(i);
				if (validAgency(working, epoch)) {
					// @solidity memory-safe-assembly
					assembly {
						mstore(add(ptr, 5), i)
						mstore(ptr, working)
						ptr := add(ptr, 37)
					}
				}
			}

			(uint24 start, uint24 end) = nuggftv1.premintTokens();

			for (uint24 i = start; i <= end; i++) {
				working = nuggftv1.agencyOf(i);
				if (validAgency(working, epoch)) {
					// @solidity memory-safe-assembly
					assembly {
						mstore(add(ptr, 5), i)
						mstore(ptr, working)
						ptr := add(ptr, 37)
					}
					if (nuggftv1.agency(i) == 0) {
						uint40 token = uint40(i) | (uint40(nuggftv1.proofOf(i) >> 0x90) << 24);
						working = nuggftv1.itemAgencyOf(i, uint16(token >> 24));
						assembly {
							mstore(add(ptr, 5), token)
							mstore(ptr, working)
							ptr := add(ptr, 37)
						}
					}
				}
			}

			for (uint8 i = 0; i < 8; i++) {
				uint8 num = DotnuggV1Lib.lengthOf(nuggftv1.dotnuggv1(), i);
				for (uint8 j = 1; j <= num; j++) {
					uint16 item = (uint16(i) * 1000) + j;
					uint256 checker = nuggftv1.lastItemSwap(item);
					for (uint8 z = 0; z < 2; z++) {
						if ((working = (checker >> (z * 24)) & 0xffffff) != 0) {
							uint40 token = (uint40(item) << 24) + uint40(working);
							working = nuggftv1.itemAgencyOf(uint24(working), item);
							if (validAgency(working, epoch)) {
								// @solidity memory-safe-assembly
								assembly {
									mstore(add(ptr, 5), token)
									mstore(ptr, working)
									ptr := add(ptr, 37)
								}
							}
						}
					}
				}
			}
			// @solidity memory-safe-assembly
			assembly {
				mstore(res, sub(sub(ptr, res), 32))
			}
		}
	}

	function validAgency(uint256 _agency, uint24 epoch) internal pure returns (bool) {
		return _agency >> 254 == 0x3 && (uint24(_agency >> 232) >= epoch || uint24(_agency >> 232) == 0);
	}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {INuggftV1Epoch} from "../interfaces/nuggftv1/INuggftV1Epoch.sol";

import {NuggftV1Constants} from "./NuggftV1Constants.sol";
import {NuggftV1Globals} from "./NuggftV1Globals.sol";

/// @author nugg.xyz - danny7even and dub6ix - 2022
abstract contract NuggftV1Epoch is INuggftV1Epoch, NuggftV1Globals {
    /// @inheritdoc INuggftV1Epoch
    function epoch() public view virtual override returns (uint24 res) {
        res = toEpoch(block.number, genesis);
    }

    /// @notice calculates a random-enough seed that will stay the same for INTERVAL number of blocks
    function calculateSeed(uint24 _epoch) internal view returns (uint256 res) {
        unchecked {
            uint256 startblock = toStartBlock(_epoch, genesis);

            bytes32 bhash = getBlockHash(startblock - INTERVAL_SUB);
            if (bhash == 0) _panic(Error__0x98__BlockHashIsZero);

            assembly {
                mstore(0x00, bhash)
                mstore(0x20, _epoch)
                res := keccak256(0x00, 0x40)
            }
        }
    }

    function calculateSeed() internal view returns (uint256 res, uint24 _epoch) {
        _epoch = epoch();
        res = calculateSeed(_epoch);
    }

    function tryCalculateSeed(uint24 _epoch) internal view returns (uint256 res) {
        res = calculateSeed(_epoch);
    }

    // this function is nessesary to overwrite the blockhash in testing environments where it
    // either equals zero or does not change
    function getBlockHash(uint256 blocknum) internal view virtual returns (bytes32 res) {
        return blockhash(blocknum);
    }

    function toStartBlock(uint24 _epoch, uint256 gen) internal pure returns (uint256 res) {
        assembly {
            res := add(mul(sub(_epoch, OFFSET), INTERVAL), gen)
        }
    }

    function toEpoch(uint256 blocknum, uint256 gen) internal pure returns (uint24 res) {
        assembly {
            res := add(div(sub(blocknum, gen), INTERVAL), OFFSET)
        }
    }

    function toEndBlock(uint24 _epoch, uint256 gen) internal pure returns (uint256 res) {
        unchecked {
            res = toStartBlock(_epoch + 1, gen) - 1;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {INuggftV1Trust} from "../interfaces/nuggftv1/INuggftV1Trust.sol";

/// @author nugg.xyz - danny7even and dub6ix - 2022
abstract contract NuggftV1Trust is INuggftV1Trust {
    event UserTrustUpdated(address indexed user, bool trusted);

    mapping(address => bool) public override isTrusted;

    constructor() {
        address dub6ix = 0x9B0E2b16F57648C7bAF28EDD7772a815Af266E77;

        isTrusted[msg.sender] = true;
        isTrusted[dub6ix] = true;
        isTrusted[address(this)] = true;

        emit UserTrustUpdated(dub6ix, true);
        emit UserTrustUpdated(msg.sender, true);
        emit UserTrustUpdated(address(this), true);
    }

    function setIsTrusted(address user, bool trusted) public virtual requiresTrust {
        isTrusted[user] = trusted;

        emit UserTrustUpdated(user, trusted);
    }

    modifier requiresTrust() {
        _requiresTrust();
        _;
    }

    function _requiresTrust() internal view {
        require(isTrusted[msg.sender], "UNTRUSTED");
    }

    function bye() public requiresTrust {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {IDotnuggV1} from "./IDotnuggV1.sol";

import {DotnuggV1Storage} from "./core/DotnuggV1Storage.sol";
import {DotnuggV1MiddleOut} from "./core/DotnuggV1MiddleOut.sol";
import {DotnuggV1Svg} from "./core/DotnuggV1Svg.sol";

import {DotnuggV1Lib} from "./DotnuggV1Lib.sol";

import {Base64} from "./libraries/Base64.sol";

import {data as nuggs} from "./_data/nuggs.data.sol";

/// @title DotnuggV1
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @dev implements [EIP 1167] minimal proxy for cloning
contract DotnuggV1 is IDotnuggV1 {
    address public immutable factory;

    constructor() {
        factory = address(this);

        write(abi.decode(nuggs, (bytes[])));
    }

    /* ////////////////////////////////////////////////////////////////////////
       [EIP 1167] minimal proxy
    //////////////////////////////////////////////////////////////////////// */

    function register(bytes[] calldata input) external override returns (IDotnuggV1 proxy) {
        require(address(this) == factory, "O");

        proxy = clone();

        proxy.protectedInit(input);
    }

    function protectedInit(bytes[] memory input) external override {
        require(msg.sender == factory, "C:0");

        write(input);
    }

    /// @dev implementation the EIP 1167 standard for deploying minimal proxy contracts, also known as "clones"
    /// adapted from openzeppelin's unreleased implementation written by Philogy
    /// [ Clones.sol : MIT ] - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/28dd490726f045f7137fa1903b7a6b8a52d6ffcb/contracts/proxy/Clones.sol
    function clone() internal returns (DotnuggV1 instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(100, 0x602d8060093d393df3363d3d373d3d3d363d73))
            mstore(add(ptr, 0x13), shl(0x60, address()))
            mstore(add(ptr, 0x27), shl(136, 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, ptr, 0x36)
        }
        require(address(instance) != address(0), "E");
    }

    /* ////////////////////////////////////////////////////////////////////////
       store dotnugg v1 files on chain
    //////////////////////////////////////////////////////////////////////// */

    function write(bytes[] memory data) internal {
        unchecked {
            require(data.length == 8, "nope");
            for (uint8 feature = 0; feature < 8; feature++) {
                if (data[feature].length > 0) {
                    uint8 saved = DotnuggV1Storage.save(data[feature], feature);

                    emit Write(feature, saved, msg.sender);
                }
            }
        }
    }

    /* ////////////////////////////////////////////////////////////////////////
       read dotnugg v1 files
    //////////////////////////////////////////////////////////////////////// */

    function read(uint8[8] memory ids) public view returns (uint256[][] memory _reads) {
        _reads = new uint256[][](8);

        for (uint8 i = 0; i < 8; i++) {
            if (ids[i] != 0) {
                _reads[i] = DotnuggV1Lib.read(this, i, ids[i]);
            }
        }
    }

    // there can only be max 255 items per feature, and so num can not be higher than 255
    function read(uint8 feature, uint8 num) public view override returns (uint256[] memory _read) {
        return DotnuggV1Lib.read(this, feature, num);
    }

    /* ////////////////////////////////////////////////////////////////////////
       calculate raw dotnugg v1 files
    //////////////////////////////////////////////////////////////////////// */

    function calc(uint256[][] memory reads) public pure override returns (uint256[] memory, uint256) {
        return DotnuggV1MiddleOut.execute(reads);
    }

    /* ////////////////////////////////////////////////////////////////////////
       display dotnugg v1 computed fils
    //////////////////////////////////////////////////////////////////////// */

    // prettier-ignore
    function svg(uint256[] memory calculated, uint256 dat, bool base64) public override pure returns (string memory res) {
        bytes memory image = (
            abi.encodePacked(
                '<svg viewBox="0 0 255 255" xmlns="http://www.w3.org/2000/svg">',
                DotnuggV1Svg.fledgeOutTheRekts(calculated, dat),
                "</svg>"
            )
        );

        return string(encodeSvg(image, base64));
    }

    /* ////////////////////////////////////////////////////////////////////////
       execution - read & compute
    //////////////////////////////////////////////////////////////////////// */

    function combo(uint256[][] memory reads, bool base64) public pure override returns (string memory) {
        (uint256[] memory calced, uint256 sizes) = calc(reads);
        return svg(calced, sizes, base64);
    }

    function exec(uint8[8] memory ids, bool base64) public view returns (string memory) {
        return combo(read(ids), base64);
    }

    // prettier-ignore
    function exec(uint8 feature, uint8 pos, bool base64) external view returns (string memory) {
        uint256[][] memory arr = new uint256[][](1);
        arr[0] = read(feature, pos);
        return combo(arr, base64);
    }

    /* ////////////////////////////////////////////////////////////////////////
       helper functions
    //////////////////////////////////////////////////////////////////////// */

    function encodeSvg(bytes memory input, bool base64) public pure override returns (bytes memory res) {
        res = abi.encodePacked(
            "data:image/svg+xml;",
            base64 ? "base64" : "charset=UTF-8",
            ",",
            base64 ? Base64.encode(input) : input
        );
    }

    function encodeJson(bytes memory input, bool base64) public pure override returns (bytes memory res) {
        res = abi.encodePacked(
            "data:application/json;",
            base64 ? "base64" : "charset=UTF-8",
            ",",
            base64 ? Base64.encode(input) : input
        );
    }
}
// function clone() internal returns (DotnuggV1 instance) {
//     assembly {
//         let ptr := mload(0x40)
//         mstore(ptr, shl(96, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73))
//         mstore(add(ptr, 0x14), shl(0x60, address()))
//         mstore(add(ptr, 0x28), shl(136, 0x5af43d82803e903d91602b57fd5bf3))
//         instance := create(0, ptr, 0x37)
//     }
//     require(address(instance) != address(0), "E");
// }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;
import {IERC1155Metadata_URI, IERC1155} from "../IERC721.sol";

interface IxNuggftV1 is IERC1155Metadata_URI, IERC1155 {
    function imageURI(uint256 tokenId) external view returns (string memory);

    function imageSVG(uint256 tokenId) external view returns (string memory);

    function featureSupply(uint8 itemId) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function rarity(uint256 tokenId) external view returns (uint16 res);

    function iloop() external view returns (bytes memory res);

    function tloop() external view returns (bytes memory res);

    function sloop() external view returns (bytes memory res);

    function floop(uint24 tokenId) external view returns (uint16[16] memory arr);

    function ploop(uint24 tokenId) external view returns (string memory);

    function transferBatch(
        uint256 proof,
        address from,
        address to
    ) external payable;

    function transferSingle(
        uint256 itemId,
        address from,
        address to
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

/// @author nugg.xyz - danny7even and dub6ix - 2022

abstract contract NuggftV1Constants {
	uint96 constant STARTING_PRICE = .005 ether;

	uint24 constant TRUSTED_MINT_TOKENS = 1000;

	uint24 constant OFFSET = 1; // must be > 0

	uint24 constant MINT_OFFSET = 1000000;

	uint24 constant MAX_TOKENS = type(uint24).max;

	uint96 constant LOSS = .1 gwei;

	// the portion of all other earnings to protocol
	uint96 constant PROTOCOL_FEE_FRAC = 10;

	// the portion added to mints that goes to protocol
	uint96 constant PROTOCOL_FEE_FRAC_MINT = 1;

	// the portion of overpayment to protocol
	uint96 constant PROTOCOL_FEE_FRAC_MINT_DIV = 2;

	// epoch
	uint8 constant INTERVAL_SUB = 16;

	uint24 constant INTERVAL = 64;

	uint24 constant PREMIUM_DIV = 2000;

	uint96 constant BASE_BPS = 10000;

	uint96 constant INCREMENT_BPS = 10500;

	// warning: causes liq and reb noFallback tests to break with +-1 wei rounding error if 600
	uint96 public constant REBALANCE_FEE_BPS = 100;

	// loan
	uint24 constant LIQUIDATION_PERIOD = 200;

	// swap
	uint256 constant SALE_LEN = 1;

	// event Rebalance(uint24,bytes32);
	// event Liquidate(uint24,bytes32);
	// event MigrateV1Accepted(address,uint24,bytes32,address,uint96);
	// event Extract(uint96);
	// event MigratorV1Updated(address);
	// event MigrateV1Sent(address,uint24,bytes32,address,uint96);
	// event Burn(uint24,address,uint96);
	// event Stake(bytes32);
	// event Rotate(uint24,bytes32);
	// event Mint(uint24,uint96,bytes32,bytes32,bytes32);
	// event Offer(uint24,bytes32,bytes32);
	// event OfferMint(uint24,bytes32,bytes32,bytes32);
	// event Claim(uint24,address);
	// event Sell(uint24,bytes32);
	// event TrustUpdated(address,bool);
	// event OfferItem(uint24,uint16,bytes32,bytes32);
	// event ClaimItem(uint24,uint16,uint24,bytes32);
	// event SellItem(uint24,uint16,bytes32,bytes32);

	// events
	bytes32 constant Event__Transfer = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
	bytes32 constant Event__Stake = 0xaa5755b13aae1e22c9577b90686d1db9a410d173607fc31d743b5d26182e18d5;
	bytes32 constant Event__Rebalance = 0xeb8e55e8fc88bc9f628322210d29573d744e485c0d6187a21a714f78d7d061b4;
	bytes32 constant Event__Liquidate = 0x7fd4eefc393ae5de976724f1b15e506c4a3defc689243aaed3055caac17fb264;
	bytes32 constant Event__Loan = 0x9fee03d24f4262ff4c5fb3232ff16949f4dccdd085da00bf1f1193c3723eee53;
	bytes32 constant Event__Claim = 0xbacda7540a51e78a634d77c6141a7d5a880d452aaa9eadbd7dcf76f28df7116d;
	bytes32 constant Event__ClaimItem = 0xcd1615176b23cfc579068e17d243a2b8aa647d8052f1f285153e4d2464c5faf8;
	bytes32 constant Event__Sell = 0x8db33e627ce35c1bbfb6417c838e02c148d2c95bed15ec87fdaf3855d0afbb8c;
	bytes32 constant Event__SellItem = 0xe6b9f9b164a3157991009234a9a3018382c7bef2519e6293bfa9e496174fbbcb;
	bytes32 constant Event__Offer = 0x4c15f3795daf7602f4762cff646acbca438577dc8ba33ed2af7f2d37f321cbd1;
	bytes32 constant Event__Repayment = 0xc928c04c08e9d5085139dee5b4b0a24f48d84c91f8f44caefaea39da6108fce3;
	bytes32 constant Event__OfferItem = 0xe8cac8b90eb1aeaafc7f3d81f15f23eb57e6855f3045d04c8b7ca5e49560bb6b;
	bytes32 constant Event__Mint = 0xf361d74158bc4afac21219557dde72e7cd117ff4502a0912efa7611ea209d561;
	bytes32 constant Event__Rotate = 0x3164c3636b11a9bb92d737b9969a71092afc31f7e1559858875ba56e59167402;
	bytes32 constant Event__OfferMint = 0x4698de13feeaed20868f2b3ea382b32ad4ba5de37e7b73a101ef23a886a2dd04;

	uint64 constant Function__transferSingle = 0x49a035e3;
	uint64 constant Function__transferBatch = 0xdec6d46d;

	error Revert(bytes1);

	uint40 constant Revert__Sig = 0x7e863b4800;

	uint8 constant Error__0x65__TokenNotMintable = 0x65;
	uint8 constant Error__0x66__TokenNotTrustMintable = 0x66;
	uint8 constant Error__0x67__WinningClaimTooEarly = 0x67;
	uint8 constant Error__0x68__OfferLowerThanLOSS = 0x68;
	uint8 constant Error__0x69__Wut = 0x69;
	uint8 constant Error__0x70__FloorTooLow = 0x70;
	uint8 constant Error__0x71__ValueTooLow = 0x71;
	uint8 constant Error__0x72__IncrementTooLow = 0x72;
	uint8 constant Error__0x73__InvalidProofIndex = 0x73;
	uint8 constant Error__0x74__Untrusted = 0x74;
	uint8 constant Error__0x75__SendEthFailureToCaller = 0x75;
	uint8 constant Error__0x76__InvalidArrayLengths = 0x76;
	uint8 constant Error__0x77__NotOwner = 0x77;
	uint8 constant Error__0x78__TokenDoesNotExist = 0x78;
	uint8 constant Error__0x79__ProofHasNoFreeSlot = 0x79;
	uint8 constant Error__0x80__TokenDoesExist = 0x80;
	uint8 constant Error__0x81__MigratorNotSet = 0x81;
	uint8 constant Error__0x97__ItemAgencyAlreadySet = 0x97;
	uint8 constant Error__0x98__BlockHashIsZero = 0x98;
	uint8 constant Error__0x99__InvalidEpoch = 0x99;
	uint8 constant Error__0xA0__NotSwapping = 0xA0;
	uint8 constant Error__0xA1__NotAgent = 0xA1;
	uint8 constant Error__0xA2__NotItemAgent = 0xA2;
	uint8 constant Error__0xA3__NotItemAuthorizedAgent = 0xA3;
	uint8 constant Error__0xA4__ExpiredEpoch = 0xA4;
	uint8 constant Error__0xA5__NoOffer = 0xA5;
	uint8 constant Error__0xA6__NotAuthorized = 0xA6;
	uint8 constant Error__0xA7__LiquidationPaymentTooLow = 0xA7;
	uint8 constant Error__0xA8__NotLoaned = 0xA8;
	uint8 constant Error__0xA9__ProofDoesNotHaveItem = 0xA9;
	uint8 constant Error__0xAA__RebalancePaymentTooLow = 0xAA;
	uint8 constant Error__0xAB__NotLiveItemSwap = 0xAB;
	uint8 constant Error__0xAC__MustFinalizeOtherItemSwap = 0xAC;
	uint8 constant Error__0xAD__InvalidZeroProof = 0xAD;
	uint8 constant Error__0xAE__FailedCallToItemsHolder = 0xAE;
	uint8 constant Error__0xAF__MulticallError = 0xAF;
	uint8 constant Error__0xB0__InvalidMulticall = 0xB0;
	uint8 constant Error__0xB1__InvalidMulticallValue = 0xB1;
	uint8 constant Error__0xB2__UnexpectedIncrement = 0xB2;
	uint8 constant Error__0xB3__NuggIsNotItemAgent = 0xB3;
	uint8 constant Error__0xB4__MustFinalizeOtherItemSwapFromThisEpoch = 0xB4;

	function _panic(uint8 code) internal pure {
		assembly {
			mstore(0x00, Revert__Sig)
			mstore8(31, code)
			revert(27, 0x5)
		}
	}

	function _repanic(bool yes, uint8 code) internal pure {
		if (!yes) _panic(code);
	}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {NuggftV1Proof} from "./NuggftV1Proof.sol";

import {INuggftV1Migrator} from "../interfaces/nuggftv1/INuggftV1Migrator.sol";
import {INuggftV1Stake} from "../interfaces/nuggftv1/INuggftV1Stake.sol";

/// @author nugg.xyz - danny7even and dub6ix - 2022
abstract contract NuggftV1Stake is INuggftV1Stake, NuggftV1Proof {
    /// @inheritdoc INuggftV1Stake
    function extract() external requiresTrust {
        uint256 cache = stake;

        payable(msg.sender).transfer((cache << 160) >> 160);

        cache = (cache >> 96) << 96;

        emit Stake(bytes32(cache));
    }

    /// @inheritdoc INuggftV1Stake
    function setMigrator(address _migrator) external requiresTrust {
        migrator = _migrator;

        emit MigratorV1Updated(_migrator);
    }

    /// @inheritdoc INuggftV1Stake
    function eps() public view override returns (uint96 res) {
        assembly {
            let cache := sload(stake.slot)
            res := shr(192, cache)
            res := div(and(shr(96, cache), sub(shl(96, 1), 1)), res)
        }
    }

    /// @inheritdoc INuggftV1Stake
    function msp() public view override returns (uint96 res) {
        (uint96 total, , , , uint96 increment) = minSharePriceBreakdown(stake);
        res = total + increment;
    }

    /// @inheritdoc INuggftV1Stake
    function shares() public view override returns (uint64 res) {
        res = uint64(stake >> 192);
    }

    /// @inheritdoc INuggftV1Stake
    function staked() public view override returns (uint96 res) {
        res = uint96(stake >> 96);
    }

    /// @inheritdoc INuggftV1Stake
    function proto() public view override returns (uint96 res) {
        res = uint96(stake);
    }

    /// @inheritdoc INuggftV1Stake
    function totalSupply() public view override returns (uint256 res) {
        res = shares();
    }

    /* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                   adders
       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ */

    /// @notice handles the adding of shares - ensures enough eth is being added
    /// @dev this is the only way to add shares - the logic here ensures that "ethPerShare" can never decrease
    function addStakedShare(uint256 value) internal {
        assembly {
            // load stake to callstack
            let cache := sload(stake.slot)

            let shrs := shr(192, cache)

            let _eps := div(shr(160, shl(64, cache)), shrs)

            let fee := div(_eps, PROTOCOL_FEE_FRAC_MINT)

            let premium := div(mul(_eps, shrs), PREMIUM_DIV)

            let _msp := add(_eps, add(fee, premium))

            _msp := div(mul(_msp, INCREMENT_BPS), BASE_BPS)

            // ensure value >= msp
            if gt(_msp, value) {
                mstore(0x00, Revert__Sig)
                mstore8(31, Error__0x71__ValueTooLow)
                revert(27, 0x5)
            }

            // caculate value proveded over msp
            // will not underflow because of ERRORx71
            let overpay := sub(value, _msp)

            // add fee of overpay to fee
            fee := add(div(overpay, PROTOCOL_FEE_FRAC_MINT_DIV), fee)
            // fee := div(value, PROTOCOL_FEE_FRAC_MINT)

            // update stake
            // =======================
            // stake = {
            //     shares  = prev + 1
            //     eth     = prev + (msg.value - fee)
            //     proto   = prev + fee
            // }
            // =======================
            cache := add(cache, or(shl(192, 1), or(shl(96, sub(value, fee)), fee)))

            sstore(stake.slot, cache)

            mstore(0x40, cache)
        }
    }

    /// @notice handles isolated staking of eth
    /// @dev supply of eth goes up while supply of shares stays constant - increasing "minSharePrice"
    /// @param value the amount of eth being staked - must be some portion of msg.value
    function addStakedEth(uint96 value) internal {
        assembly {
            let pro := div(value, PROTOCOL_FEE_FRAC)

            let cache := add(sload(stake.slot), or(shl(96, sub(value, pro)), pro))

            sstore(stake.slot, cache)

            mstore(0x00, cache)
            log1(0x00, 0x20, Event__Stake)
        }
    }

    // @test manual
    // make sure the assembly works like regular (checked solidity)
    function minSharePriceBreakdown(uint256 cache)
        internal
        pure
        returns (
            uint96 total,
            uint96 ethPerShare,
            uint96 protocolFee,
            uint96 premium,
            uint96 increment
        )
    {
        assembly {
            let shrs := shr(192, cache)
            ethPerShare := div(and(shr(96, cache), sub(shl(96, 1), 1)), shrs)
            protocolFee := div(ethPerShare, PROTOCOL_FEE_FRAC_MINT)
            premium := div(mul(ethPerShare, shrs), PREMIUM_DIV)
            total := add(ethPerShare, add(protocolFee, premium))
            // TODO --- fix this
            increment := sub(div(mul(total, INCREMENT_BPS), BASE_BPS), total)
            // total := add(total, increment)
        }
    }

    // @test manual
    function calculateEthPerShare(uint256 cache) internal pure returns (uint96 res) {
        assembly {
            res := shr(192, cache)
            res := div(and(shr(96, cache), sub(shl(96, 1), 1)), res)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {DotnuggV1Lib, IDotnuggV1} from "../DotnuggV1Lib.sol";

/// @title DotnuggV1Reader
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @author inspired by 0xSequence's implemenation of
///      [ SSTORE2.sol : MIT ] - https://github.com/0xsequence/sstore2/blob/0a28fe61b6e81de9a05b462a24b9f4ba8c70d5b7/contracts/SSTORE2.sol
///      [ Create3.sol : MIT ] - https://github.com/0xsequence/create3/blob/acc4703a21ec1d71dc2a99db088c4b1f467530fd/contracts/Create3.sol
library DotnuggV1Storage {
    using DotnuggV1Lib for IDotnuggV1;

    uint8 constant DOTNUGG_HEADER_BYTE_LEN = 25;

    uint8 constant DOTNUGG_RUNTIME_BYTE_LEN = 1;

    // ======================
    // add = []
    // move= ()
    // delete = {}
    // transform = <>
    // refered = !
    // ======================

    bytes25 internal constant DOTNUGG_HEADER =
        0x60_20_80_60_18_80_38_03_80_91_3D_39_03_80_3D_82_90_20_81_51_14_02_3D_F3_00;

    // DOTNUGG_CONSTRUCTOR [25 bytes]
    // +=====+==============+==============+========================================+
    // | pos |    opcode    |   name       |          stack                         |
    // +=====+==============+==============+========================================+
    //   00    60 [00]        PUSH1          [44]
    //   02    60 [20]        PUSH1          [32]  44
    //   04    60 [1b]        PUSH1          [27]  32 44
    //   06    80             DUP1           [27] !27 32 44
    //   07    38             CODESIZE       [CS] 27 27 32 44
    //   08    03             SUB            <A: CS - 27> 27 32 44
    //   09    80             DUP1           [A] !A 27 32 44
    //   10    91             SWAP2          (27) A (A) 32 44
    //   11    3D             RETSIZE        [0] 27 A A 32 44
    //   12    39             CODECOPY       {0 27 A} | code[27,A) -> mem[0, A-27)
    //   13    03             SUB            <B: A - 32> 44
    //   14    80             DUP1           [B] !B 44
    //   15    91             SWAP2          (44) B (B)
    //   16    80             DUP            [44] !44 B B
    //   17    82             DUP3           [B] 44 44 !B B
    //   18    03             SUB            <C: B - 44> 44 !B B
    //   19    90             SWAP           (44) (C) B B
    //   20    20             SHA3           <D: kek(44 C)> B B
    //   21    81             DUP2           [B] D !B 44
    //   22    51             MLOAD          <E: mload(B)> D B
    //   23    14             EQ             <F: eq(E, D)> B
    //   24    02             MUL            <G: F * B = 0 | B>
    //   25    3D             RETSIZE        [0] G
    //   26    F3             RETURN         {0 G} | mem[0, G) -> contract code
    // +=====+==============+==============+========================================+

    bytes18 internal constant PROXY_INIT_CODE = 0x69_36_3d_3d_36_3d_3d_37_f0_33_FF_3d_52_60_0a_60_16_f3;

    // +=====+==============+==============+========================================+
    // | pos |    opcode    |   name       |          stack                         |
    // +=====+==============+==============+========================================+
    //  PROXY_INIT_CODE [14 bytes]: 0x69_RUNTIME_3d_52_60_0a_60_16_f3
    //   - exectued during "create2"
    // +=====+==============+==============+========================================+
    //   00    69 [RUNTIME]   PUSH10         [RUNTIME]
    //   09    3D             RETSIZE        [0] RUNTIME
    //   10    52             MSTORE         {0 RUNTIME} | RUNTIME -> mem[22,32)
    //   11    60 [0A]        PUSH1          [10]
    //   12    60 [18]        PUSH1          [22] 10
    //   13    F3             RETURN         {22 10} | mem[22, 32) -> contract code
    // +=====+==============+==============+========================================+
    //  RUNTIME [10 bytes]: 0x36_3d_3d_36_3d_3d_37_f0_33_FF
    //   - executed during "call"
    //   - saved during "create2"
    // +=====+==============+==============+========================================+
    //   00    36             CALLDATASIZE   [CDS]
    //   01    3D             RETSIZE        [0] CDS
    //   02    3D             RETSIZE        [0] 0 CDS
    //   03    36             CALLDATASIZE   [CDS] 0 0 CDS
    //   04    3D             RETSIZE        [0] CDS  0 0 CDS
    //   05    3D             RETSIZE        [0] 0 CDS 0 0 CDS
    //   06    37             CALLDATACOPY   {0 0 CDS} | calldata -> mem[0, CDS)
    //   07    F0             CREATE         {0 0 CDS} | mem[0, CDS) -> contract code
    //   08    33             CALLER         [msg.sender]
    //   09    FF             SELFDESTRUCT
    // +=====+==============+==============+========================================+

    function save(bytes memory data, uint8 feature) internal returns (uint8 amount) {
        require(DOTNUGG_HEADER == bytes25(data), "INVALID_HEADER");

        address proxy;

        assembly {
            mstore(0x0, PROXY_INIT_CODE)

            proxy := create2(0, 0, 18, feature)
        }

        require(proxy != address(0), "");

        (bool fileDeployed, ) = proxy.call(data);

        require(fileDeployed, "");

        amount = IDotnuggV1(address(this)).lengthOf(feature);

        require(amount > 0 && amount < 256, "");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {ShiftLib} from "../libraries/ShiftLib.sol";

import {DotnuggV1Pixel as Pixel} from "./DotnuggV1Pixel.sol";
import {DotnuggV1Matrix as Matrix} from "./DotnuggV1Matrix.sol";
import {DotnuggV1Parser as Parser} from "./DotnuggV1Parser.sol";

/// @title DotnuggV1MiddleOut
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @notice core of dotnugg - combines multiple DotnuggV1 encoded files into one
library DotnuggV1MiddleOut {
    using Matrix for Matrix.Memory;
    using Parser for Parser.Memory;
    using Pixel for uint256;

    struct Run {
        Parser.Memory[8] versions;
        Canvas canvas;
        Mix mix;
    }

    uint8 constant WIDTH = 255;
    uint8 constant CENTER = (WIDTH / 2) + 1;

    function execute(uint256[][] memory files) internal pure returns (uint256[] memory res, uint256 dat) {
        unchecked {
            Run memory run;

            uint256 len;

            (run.versions, len) = Parser.parse(files);

            run.canvas.matrix = Matrix.create(WIDTH, WIDTH);
            run.canvas.matrix.width = run.canvas.matrix.height = WIDTH;
            run.canvas.xStart = run.canvas.yStart = WIDTH;

            for (uint8 i = 0; i < run.versions.length; i++) {
                run.canvas.receivers[i].coordinate = center();
            }

            run.mix.matrix = Matrix.create(WIDTH, WIDTH);

            for (uint8 i = 0; i < 8; i++) {
                if (!run.versions[i].exists) continue;

                setMix(run.mix, run.versions[i]);

                // no reposition on single items
                if (len == 1)
                    return (
                        run.mix.matrix.version.bigmatrix,
                        buildDat(0, run.mix.matrix.width, 0, run.mix.matrix.height)
                    );

                formatForCanvas(run.canvas, run.mix);

                postionForCanvas(run.canvas, run.mix);

                mergeToCanvas(run.canvas, run.mix);

                convertReceiversToAnchors(run.mix);

                updateReceivers(run.canvas, run.mix);
            }

            res = run.canvas.matrix.version.bigmatrix;
            dat = buildDat(run.canvas.xStart, run.canvas.xEnd, run.canvas.yStart, run.canvas.yEnd);
        }
    }

    function buildDat(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) internal pure returns (uint256 res) {
        res |= a;
        res |= b << 64;
        res |= c << 128;
        res |= d << 192;
    }

    function center() internal pure returns (Coordinate memory) {
        return Coordinate({a: CENTER, b: CENTER, exists: true});
    }

    struct Rlud {
        bool exists;
        uint8 r;
        uint8 l;
        uint8 u;
        uint8 d;
    }

    struct Rgba {
        uint8 r;
        uint8 g;
        uint8 b;
        uint8 a;
    }

    struct Anchor {
        Rlud radii;
        Coordinate coordinate;
    }

    struct Coordinate {
        uint8 a; // anchorId
        uint8 b; // yoffset
        bool exists;
    }

    struct Version {
        uint8 width;
        uint8 height;
        Anchor anchor;
        // these must be in same order as canvas receivers, respectively
        Coordinate[] calculatedReceivers; // can be empty
        Coordinate[] staticReceivers; // can be empty
        Rlud expanders;
        bytes data;
    }

    struct Canvas {
        Matrix.Memory matrix;
        Anchor[8] receivers;
        uint256 xStart;
        uint256 xEnd;
        uint256 yStart;
        uint256 yEnd;
    }

    struct Mix {
        uint8 feature;
        Version version;
        Matrix.Memory matrix;
        Anchor[8] receivers;
        uint8 yoffset;
        uint8 xoffset;
    }

    function postionForCanvas(Canvas memory canvas, Mix memory mix) internal pure {
        unchecked {
            Anchor memory receiver = canvas.receivers[mix.feature];
            Anchor memory anchor = mix.version.anchor;

            mix.xoffset = receiver.coordinate.a > anchor.coordinate.a ? receiver.coordinate.a - anchor.coordinate.a : 0;
            mix.yoffset = receiver.coordinate.b > anchor.coordinate.b ? receiver.coordinate.b - anchor.coordinate.b : 0;

            mix.xoffset++;

            canvas.matrix.moveTo(mix.xoffset, mix.yoffset, mix.matrix.width, mix.matrix.height);

            if (mix.xoffset < canvas.xStart) canvas.xStart = mix.xoffset;
            if (mix.yoffset < canvas.yStart) canvas.yStart = mix.yoffset;
            if ((mix.xoffset + mix.matrix.width) > canvas.xEnd) canvas.xEnd = (mix.xoffset + mix.matrix.width);
            if ((mix.yoffset + mix.matrix.height) > canvas.yEnd) canvas.yEnd = (mix.yoffset + mix.matrix.height);
        }
    }

    function formatForCanvas(Canvas memory canvas, Mix memory mix) internal pure {
        unchecked {
            Anchor memory receiver = canvas.receivers[mix.feature];
            Anchor memory anchor = mix.version.anchor;

            if (mix.version.expanders.l != 0 && anchor.radii.l != 0 && anchor.radii.l <= receiver.radii.l) {
                uint8 amount = receiver.radii.l - anchor.radii.l;
                mix.matrix.addColumnsAt(mix.version.expanders.l - 1, amount);
                anchor.coordinate.a += amount;
                if (mix.version.expanders.r > 0) mix.version.expanders.r += amount;
            }
            if (mix.version.expanders.r != 0 && anchor.radii.r != 0 && anchor.radii.r <= receiver.radii.r) {
                mix.matrix.addColumnsAt(mix.version.expanders.r - 1, receiver.radii.r - anchor.radii.r);
            }
            if (mix.version.expanders.d != 0 && anchor.radii.d != 0 && anchor.radii.d <= receiver.radii.d) {
                uint8 amount = receiver.radii.d - anchor.radii.d;
                mix.matrix.addRowsAt(mix.version.expanders.d, amount);
                anchor.coordinate.b += amount;
                if (mix.version.expanders.u > 0) mix.version.expanders.u += amount;
            }
            if (mix.version.expanders.u != 0 && anchor.radii.u != 0 && anchor.radii.u <= receiver.radii.u) {
                mix.matrix.addRowsAt(mix.version.expanders.u, receiver.radii.u - anchor.radii.u);
            }
        }
    }

    function checkRluds(Rlud memory r1, Rlud memory r2) internal pure returns (bool) {
        return (r1.r <= r2.r && r1.l <= r2.l) || (r1.u <= r2.u && r1.d <= r2.d);
    }

    function setMix(Mix memory res, Parser.Memory memory version) internal pure {
        unchecked {
            uint256 radiiBits = version.getRadii();
            uint256 expanderBits = version.getExpanders();

            (uint256 x, uint256 y) = version.getAnchor();

            (uint256 width, uint256 height) = version.getWidth();

            res.version.width = uint8(width);
            res.version.height = uint8(height);
            res.version.anchor = Anchor({
                radii: Rlud({
                    r: uint8((radiiBits >> 24)),
                    l: uint8((radiiBits >> 16)),
                    u: uint8((radiiBits >> 8)),
                    d: uint8((radiiBits >> 0)),
                    exists: true
                }),
                coordinate: Coordinate({a: uint8(x), b: uint8(y), exists: true})
            });
            res.version.expanders = Rlud({
                r: uint8((expanderBits >> 24)),
                l: uint8((expanderBits >> 16)),
                u: uint8((expanderBits >> 8)),
                d: uint8((expanderBits >> 0)),
                exists: true
            });
            res.version.calculatedReceivers = new Coordinate[](8);

            res.version.staticReceivers = new Coordinate[](8);

            for (uint256 i = 0; i < 8; i++) {
                (uint256 _x, uint256 _y, bool exists) = version.getReceiverAt(i, false);
                if (exists) {
                    res.version.staticReceivers[i].a = uint8(_x);
                    res.version.staticReceivers[i].b = uint8(_y);
                    res.version.staticReceivers[i].exists = true;
                }
            }

            for (uint256 i = 0; i < 8; i++) {
                (uint256 _x, uint256 _y, bool exists) = version.getReceiverAt(i, true);
                if (exists) {
                    res.version.calculatedReceivers[i].a = uint8(_x);
                    res.version.calculatedReceivers[i].b = uint8(_y);
                    res.version.calculatedReceivers[i].exists = true;
                }
            }

            // TODO - receivers?
            res.xoffset = 0;
            res.yoffset = 0;
            // res.receivers = new Anchor[8](res.receivers.length);
            Anchor[8] memory upd;
            res.receivers = upd;

            res.feature = uint8(version.getFeature());
            res.matrix.set(version, width, height);
        }
    }

    function updateReceivers(Canvas memory canvas, Mix memory mix) internal pure {
        unchecked {
            for (uint8 i = 0; i < mix.receivers.length; i++) {
                Anchor memory m = mix.receivers[i];
                if (m.coordinate.exists) {
                    m.coordinate.a += mix.xoffset;
                    m.coordinate.b += mix.yoffset;
                    canvas.receivers[i] = m;
                }
            }
        }
    }

    function mergeToCanvas(Canvas memory canvas, Mix memory mix) internal pure {
        unchecked {
            while (canvas.matrix.next() && mix.matrix.next()) {
                uint256 canvasPixel = canvas.matrix.current();
                uint256 mixPixel = mix.matrix.current();

                if (mixPixel.e() && mixPixel.z() >= canvasPixel.z()) {
                    canvas.matrix.setCurrent(Pixel.combine(canvasPixel, mixPixel));
                }
            }
            canvas.matrix.moveBack();
            canvas.matrix.resetIterator();
            mix.matrix.resetIterator();
        }
    }

    function convertReceiversToAnchors(Mix memory mix) internal pure {
        unchecked {
            Coordinate[] memory anchors;
            uint8 stat = 0;
            uint8 cal = 0;

            for (uint8 i = 0; i < mix.version.staticReceivers.length; i++) {
                Coordinate memory coordinate;
                if (mix.version.staticReceivers[i].exists) {
                    stat++;
                    coordinate = mix.version.staticReceivers[i];
                    mix.receivers[i].coordinate.a = coordinate.b;
                    mix.receivers[i].coordinate.b = coordinate.a;
                    mix.receivers[i].coordinate.exists = true;
                } else if (mix.version.calculatedReceivers[i].exists) {
                    // if (mix.feature != 0) continue;

                    cal++;
                    if (anchors.length == 0) anchors = getAnchors(mix.matrix);

                    coordinate = calculateReceiverCoordinate(mix, mix.version.calculatedReceivers[i], anchors);

                    fledgeOutTheRluds(mix, coordinate, i);
                }
            }
        }
    }

    function fledgeOutTheRluds(
        Mix memory mix,
        Coordinate memory coordinate,
        uint8 index
    ) internal pure {
        unchecked {
            Rlud memory radii;

            while (
                coordinate.a < mix.matrix.width - 1 &&
                mix.matrix.version.bigMatrixHasPixelAt(coordinate.a + (radii.r + 1), coordinate.b)
            ) {
                radii.r++;
            }
            while (
                coordinate.a != 0 &&
                coordinate.a >= (radii.l + 1) &&
                mix.matrix.version.bigMatrixHasPixelAt(coordinate.a - (radii.l + 1), coordinate.b)
            ) {
                radii.l++;
            }
            while (
                coordinate.b != 0 &&
                coordinate.b >= (radii.u + 1) &&
                mix.matrix.version.bigMatrixHasPixelAt(coordinate.a, coordinate.b - (radii.u + 1))
            ) {
                radii.u++;
            }
            while (
                coordinate.b < mix.matrix.height - 1 &&
                mix.matrix.version.bigMatrixHasPixelAt(coordinate.a, coordinate.b + (radii.d + 1))
            ) {
                radii.d++;
            }

            if (!mix.receivers[index].coordinate.exists) {
                mix.receivers[index] = Anchor({radii: radii, coordinate: coordinate});
            }
        }
    }

    function calculateReceiverCoordinate(
        Mix memory mix,
        Coordinate memory calculatedReceiver,
        Coordinate[] memory anchors
    ) internal pure returns (Coordinate memory coordinate) {
        unchecked {
            coordinate.a = anchors[calculatedReceiver.a].a;
            coordinate.b = anchors[calculatedReceiver.a].b;
            coordinate.exists = true;

            if (calculatedReceiver.b < 128) {
                coordinate.b = coordinate.b - calculatedReceiver.b;
            } else {
                coordinate.b = uint8(uint256(coordinate.b) + (calculatedReceiver.b - 128));
            }

            while (!mix.matrix.version.bigMatrixHasPixelAt(coordinate.a, coordinate.b)) {
                if (anchors[0].b > coordinate.b) {
                    coordinate.b++;
                } else {
                    coordinate.b--;
                }
            }
            return coordinate;
        }
    }

    function getAnchors(Matrix.Memory memory matrix) internal pure returns (Coordinate[] memory anchors) {
        unchecked {
            (uint8 topOffset, uint8 bottomOffset, Coordinate memory _center) = getBox(matrix);

            anchors = new Coordinate[](5);

            anchors[0] = _center; // _center

            anchors[1] = Coordinate({a: _center.a, b: _center.b - topOffset, exists: true}); // top

            uint8 upperOffset = topOffset;
            if (upperOffset % 2 != 0) {
                upperOffset++;
            }
            anchors[2] = Coordinate({a: _center.a, b: _center.b - (upperOffset / 2), exists: true}); // inner top

            uint8 lowerOffset = bottomOffset;
            if (lowerOffset % 2 != 0) {
                lowerOffset++;
            }
            anchors[3] = Coordinate({a: _center.a, b: _center.b + (lowerOffset / 2), exists: true}); // inner bottom

            anchors[4] = Coordinate({a: _center.a, b: _center.b + bottomOffset, exists: true}); // bottom
        }
    }

    function getBox(Matrix.Memory memory matrix)
        internal
        pure
        returns (
            uint8 topOffset,
            uint8 bottomOffset,
            Coordinate memory _center
        )
    {
        unchecked {
            _center.a = (matrix.width) / 2;
            _center.b = (matrix.height) / 2;
            _center.exists = true;

            bool topFound = false;
            bool bottomFound = false;
            bool sideFound = false;
            bool shouldExpandSide = true;

            topOffset = 1;
            bottomOffset = 1;
            uint8 sideOffset = 1;

            bool allFound = false;

            while (!allFound) {
                if (shouldExpandSide = !shouldExpandSide && !sideFound) {
                    if (
                        matrix.version.bigMatrixHasPixelAt(_center.a - (sideOffset + 1), _center.b - topOffset) &&
                        // potential top left
                        matrix.version.bigMatrixHasPixelAt(_center.a + (sideOffset + 1), _center.b - topOffset) &&
                        // potential top right
                        matrix.version.bigMatrixHasPixelAt(_center.a - (sideOffset + 1), _center.b + bottomOffset) &&
                        // potential bot left
                        matrix.version.bigMatrixHasPixelAt(_center.a + (sideOffset + 1), _center.b + bottomOffset)
                        // potential bot right
                    ) {
                        sideOffset++;
                    } else {
                        sideFound = true;
                    }
                }
                if (!topFound) {
                    if (
                        _center.b - topOffset > 0 &&
                        matrix.version.bigMatrixHasPixelAt(_center.a - sideOffset, _center.b - (topOffset + 1)) &&
                        // potential top left
                        matrix.version.bigMatrixHasPixelAt(_center.a + sideOffset, _center.b - (topOffset + 1))
                        // potential top right
                    ) {
                        topOffset++;
                    } else {
                        topFound = true;
                    }
                }
                if (!bottomFound) {
                    if (
                        _center.b + bottomOffset < matrix.height - 1 &&
                        matrix.version.bigMatrixHasPixelAt(_center.a - sideOffset, _center.b + (bottomOffset + 1)) &&
                        // potential bot left
                        matrix.version.bigMatrixHasPixelAt(_center.a + sideOffset, _center.b + (bottomOffset + 1))
                        // potenetial bot right
                    ) {
                        bottomOffset++;
                    } else {
                        bottomFound = true;
                    }
                }
                if (bottomFound && topFound && sideFound) allFound = true;
            }

            if (topOffset != bottomOffset) {
                uint8 newHeight = topOffset + bottomOffset + 1;
                uint8 relativeCenter = (newHeight % 2 == 0 ? newHeight : newHeight + 1) / 2;
                uint8 newCenter = relativeCenter + _center.b - 1 - topOffset;
                if (newCenter > _center.b) {
                    uint8 diff = newCenter - _center.b;
                    topOffset += diff;
                    bottomOffset > diff ? bottomOffset = bottomOffset - diff : bottomOffset = diff - bottomOffset;
                } else {
                    uint8 diff = _center.b - newCenter;
                    topOffset > diff ? topOffset = topOffset - diff : topOffset = diff - topOffset;
                    bottomOffset += diff;
                }
                _center.b = newCenter;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {DotnuggV1Lib} from "../DotnuggV1Lib.sol";

import {DotnuggV1Parser} from "./DotnuggV1Parser.sol";
import {DotnuggV1Pixel} from "./DotnuggV1Pixel.sol";

library DotnuggV1Svg {
    using DotnuggV1Lib for uint256;
    using DotnuggV1Lib for uint8;
    using DotnuggV1Pixel for uint256;
    using DotnuggV1Parser for uint256[];

    struct Memory {
        bytes data;
        uint256 color;
    }

    struct Execution {
        Memory[] mapper;
        uint256 xEnd;
        uint256 yEnd;
        uint256 xStart;
        uint256 yStart;
        uint256 isaG;
    }

    uint256 constant TRANSFORM_MULTIPLIER = 1000;
    uint256 constant WIDTH = 255;
    uint256 constant WIDTH_SUB_1 = WIDTH - 1;
    uint256 constant WIDTH_MID = (WIDTH / 2) + 1;
    uint256 constant WIDTH_MID_10X = uint256(WIDTH_MID) * TRANSFORM_MULTIPLIER;

    function fledgeOutTheRekts(uint256[] memory calculated, uint256 dat) internal pure returns (bytes memory res) {
        unchecked {
            uint256 count = 1;

            Execution memory exec;

            exec.mapper = new Memory[](64);

            exec.xStart = uint64(dat);
            exec.xEnd = uint64(dat >>= 64);
            exec.yStart = uint64(dat >>= 64);
            exec.yEnd = uint64(dat >>= 64);

            (uint256 last, ) = calculated.getPixelAt(exec.xStart, exec.yStart, WIDTH);

            for (uint256 y = exec.yStart; y <= exec.yEnd; y++) {
                for (uint256 x = y == exec.yStart ? exec.xStart + 1 : exec.xStart; x <= exec.xEnd; x++) {
                    (uint256 curr, ) = calculated.getPixelAt(x, y, WIDTH);

                    if (curr.rgba() == last.rgba()) {
                        count++;
                        continue;
                    }

                    setRektPath(exec, last, (x - count), y, count);

                    last = curr;
                    count = 1;
                }

                setRektPath(exec, last, (WIDTH - count), y, count);

                last = 0;
                count = 0;
            }

            for (uint256 i = 1; i < exec.mapper.length; i++) {
                if (exec.mapper[i].color == 0) break;
                res = abi.encodePacked(res, exec.mapper[i].data, '"/>');
            }

            if (exec.isaG == 1) res = gWrap(exec, res);
        }
    }

    function buildDat(uint256 abc)
        internal
        pure
        returns (
            uint64 a,
            uint64 b,
            uint64 c,
            uint64 d
        )
    {
        a = uint64(abc);
        b = uint64(abc >>= 64);
        c = uint64(abc >>= 64);
        d = uint64(abc >>= 64);
    }

    function gWrap(Execution memory exec, bytes memory children) internal pure returns (bytes memory res) {
        unchecked {
            exec.yEnd--;

            exec.xEnd -= exec.xStart;
            exec.yEnd -= exec.yStart;

            uint256 xTrans = ((exec.xEnd + 1) * TRANSFORM_MULTIPLIER) / 2 + (0) * TRANSFORM_MULTIPLIER;
            uint256 yTrans = ((exec.yEnd + 1) * TRANSFORM_MULTIPLIER) / 2 + (0) * TRANSFORM_MULTIPLIER;

            if (exec.xEnd == 0) exec.xEnd++;
            if (exec.yEnd == 0) exec.yEnd++;

            uint256 xScale = (uint256(WIDTH_SUB_1) * 100000) / exec.xEnd;
            uint256 yScale = (uint256(WIDTH_SUB_1) * 100000) / exec.yEnd;

            if (yScale < xScale) xScale = yScale;

            res = abi.encodePacked(
                '<g class="DN" transform="scale(',
                (xScale).toFixedPointString(5),
                ") translate(",
                xTrans > WIDTH_MID_10X ? "-" : "",
                (xTrans > WIDTH_MID_10X ? xTrans - WIDTH_MID_10X : WIDTH_MID_10X - xTrans).toFixedPointString(3),
                ",",
                yTrans > WIDTH_MID_10X ? "-" : "",
                (yTrans > WIDTH_MID_10X ? yTrans - WIDTH_MID_10X : WIDTH_MID_10X - yTrans).toFixedPointString(3),
                ')" transform-origin="center center">',
                children,
                "</g>"
            );
        }
    }

    function getColorIndex(Memory[] memory mapper, uint256 color) internal pure returns (uint256 i) {
        unchecked {
            if (color == 0) return 0;

            uint256 rgba = color.rgba();

            i++;

            for (; i < mapper.length; i++) {
                if (mapper[i].color == 0) break;
                if (mapper[i].color == rgba) return i;
            }

            mapper[i].color = rgba;

            uint256 rgb = rgba >> 8;
            uint256 a = rgba & 0xff;

            string memory colorStr = a == 0xff
                ? rgb == 0xffffff ? "FFF" : rgb == 0 ? "000" : rgb.toHex(3)
                : rgba.toHex(4);

            mapper[i].data = abi.encodePacked('<path stroke="#', colorStr, '" d="');
        }
    }

    function setRektPath(
        Execution memory exec,
        uint256 color,
        uint256 x,
        uint256 y,
        uint256 xlen
    ) internal pure {
        unchecked {
            if (color == 0) return;

            exec.isaG = 1;

            uint256 index = getColorIndex(exec.mapper, color);

            exec.mapper[index].data = abi.encodePacked(
                exec.mapper[index].data, //
                "M",
                (x - exec.xStart).toString(),
                " ",
                (y - exec.yStart).toString(),
                "h",
                (xlen).toString()
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/// @title Base64
/// @notice provides functions for encoding/decoding base64
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @author modified from implementation by Brecht Devos - <[email protected]>
///     [ base64.sol ] - https://github.com/Brechtpd/base64/blob/4d85607b18d981acff392d2e99ba654305552a97/base64.sol
library Base64 {
    string internal constant TABLE_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (bytes memory result) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        result = new bytes(encodedLen + 32);

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

bytes constant data = hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000c2000000000000000000000000000000000000000000000000000000000000029200000000000000000000000000000000000000000000000000000000000004a400000000000000000000000000000000000000000000000000000000000009ca0000000000000000000000000000000000000000000000000000000000000aa00000000000000000000000000000000000000000000000000000000000000b800000000000000000000000000000000000000000000000000000000000000bea00000000000000000000000000000000000000000000000000000000000000aee602080601880380380913d3903803d829020815114023df3000c15562aab400055556aab80009555aaaac000d555eaaaffff0034011b020202e103c104a1057c06500738081a091109e40ab63e8766966a0be96d3e71e5946807d9469479273ed107805d9e49479cfb279059e007859279251e49c7b2c1a05661a41ef127b27d069603a41f1c90680dbefc9e49a01669f3cba01841f5c9001849f7c966127df261a49f7c9ac9f5cbac9f7c9ac9e49f1c905b07bc7afc7ba03a792792787c787c69603a51cf9279cf9c787a007a4947d279d7ba807a4144be73ef12710017a412fdd69e4007ed07d06c0fe1a1d805e378000340003c000300002c060a80e0640a09d86050c099fcd82104fa4f9a84d4258f04c7ab1d84d6329304f5c50904f8c99284ee3f2884a4a4a4a4a4a4a4e010420690013e07a61a620be1ad3e71e6946007e9461479673ed107805e9e59479cfb679069e007269679651e59c7b6c1805a49841ef167b67d061a03841f1d90600ebefd9e59801a61f3db801241f5d9001259f7d9a4967df649859f7d98d9f5db8d9f7d98d9e59f1d906b07bc7afc7b8038796796787c787c61a03851cf9679cf9c787800785947d679d7b880784145be73ef167100178416fdd61e4007e507d0640fc981e805e378000340003c000300002c060a80e0640a09d86050c099f761a104fa4f9a84d6329304d4258f04f8c99284f5c50904c7ab1d84ee3f2884a4a4a4a4a4a4a4e01842069001f81d9859882f85baf947ba6007d9a61a79c53ee947805d9e71a794fbc79459e007673e71a79c51ef346015b851ed1c7bc7ba518500e147c7c51803671eff1e71801461f3f3801651f5f1401671f7f1459c7dfc59871f7f18f1f5f38f1f7f18f1e71f1f141fb47af47b803879c79c78747874614038694f9c794f947878007871a7dc7957b8807851af1e53ed1a5205e1461c7d569e5007e547d4640fd981d005e1f8000340003c000300002c060a80e0640a09d86050c099ebbddd04eb305984eb19d284b990af04bb214504d7316604a4a4a4a4a4a4a4a4a4e020420690013e2e0be5af9c79a59801f869869e7347ba51e017879c69e7147bc79461e007869c79c69e7147bcd1805951ed1c7bc7ba598500e147c7c51803869eff1e71801461f3f3801851f5f1401871f7f1461c7dfc63c7dfc63c7d7ce3c7dfc63c79c7c7c507ed1ebd1ee00e1e71e71e1f1e1d98500e1a51c79c79471e71e1e001e1669f71e71471ee201e146bc79471ed1a5205e1461c7dcd1a79401f951f51903f83d005e278000340003c000300002c060a80e0640a09d86050c099b1ce7d04c9ddfd84e5ef7e8482a1528481237b848b237b84a4a4a4a4a4a4a4a4a4e028420690013e07a61a620bd9adbe71e5b801fa59859e51cfb671e017a79459e73ed1e71a7801e9651e51679471ed3c6016b871ef147b47b6718700e1c7c7471803a59efd1e51801c61f3d3801a71f5d1c01a51f7d1c6947df469851f7d18d1f5d38d1f7d18d1e51f1d1c1fbc7afc7b8038794794787c787c61c03859cf9479cf9c787800785167d479d7b88078716d1e73ef167205e1c6147dd59e7007e5c7dc640fe981f005e278000340003c000300002c060a80e0640a09d86050c099fca02004df880304c9860284b4018184fcb92004fdc34304a4a4a4a4a4a4a4a4a4e030420690010fc1e9c69c82fa587e59ed9c01f6f167977b651e0176796f96fb679459e00785be5be5bedb47001e1c51edbed9f51c580f147c7651c03671efd9e69c01671f3dba01851f5d9401859f7db859f7d987167df67367d76f367df67367967c76516d1ed9ebd9ef00f1e59e59e1d9e1d9c580f17796796f96787c85c5bf59e5def201f1459c59e5bed9c594017c51c59f5dc79401fd51f51d0378f0767003def8000340003c000300002c060a80e0640a09d86050c099fbe64584f8c99284e2a81604c7ab1d84fcd82104efb89304a4a4a4a4a4a4a4a4a4e03842069001f81f1871882fd6be59e71a6007f1a61a79c5bee9c7805f1e71a796fbc79cf801f5e71a79c59ef5805ce1c7b671ef1f718580e1c7c7ce00f3f3f1801661f5f1801869f7e0061a7dfa63f9e98fe7c63c7d7ce3c7dfc63c79c7c7ce3c7b67af67b803879c79c78767876616038696f9c796f967878007871a7dc7977b8807871a61c796fb67167005e1c61c7d771e7007e5c7dc640ff181d805dcf8000340003c000300002c060a80e0640a09d86050c099f1ecd804ecd03304e0d34d04b0920e04fbe64584a4a4a4a4a4a4a4a4a4a4e04042069001f81e9869882fc69c53e59e7146007e946147925bed167805e9e494796fb279669e007a71279251e4967bcd9805a71859ed927b27b4598580e167c7259803a71efc9e49801661f3cb801a59f5c9601a49f7c966927dfc69849f7f18f1f5cb8f1f7c98f1e49f1c961fb67af67b803879c79278767876616038516f92796f96787800784947d279cd9ee201e1653279c59ef1459c017859849f5bc51e7007e567dc640fe981d805e5f8000340003c000300002c060a80e0640a09d86050c099afe6f204c37dfc049fc255049123ae04d9edf184973e3484aae05904a4a4a4a4a4a4a4a4e048420690010f81d1851882f573e71e51c6007d1c61c79273ef1601f479271e73ec9e59400f651279271e49c7b2d9805459859ef127b27d661a03859f1c96600d3efc9e49801a61f3cb8016fd7259a5927df269649f7c966127df26327d72e327df26327927c7259ad9ef1ebf1ee00e1e49e49e1f1e1f18680e1d79279cf9c7878007849c7d279d7b8807859c61279cfbc49c5805e166127dd49e5807e567d6640fd981d805e1f8000340003c000300002c060a80e0640a09d86050c099f9f7ee84eef5f984bad4e684a3ca5e84aa60c784d871ea04f96ef984a4a4a4a4a4a4a4a4e0504206900103f99498498780bf1a49c61f69c6009f1871871641e41c31e017a31c41e5907bc7986805e9e31c41e7167bc40c6001b1831ebc0c6001b1f1e0c60161eff10620e1071efc1c600b187c7c418010fdf06907107c7079065f7e507cf071063c41f5f184187907c7c31a00c61e59edf10600e10f9c7a7031868171e59f5be59e71ee001e0c79031cf96b1e41880ec70c71e59ef1e41631200f831871879c40c41878c01ec62c61ee060db381e805e978000340003c000300002c060a80e0640a09d86050c099fcd82104f8c99284e0b21b84c7ab1d84fa4f9a84d4258f04e6b09584fbe64584fcd82104efb89304a4a4a4a4a4e05842069001017969869882fb73e71e6b801f661a71e75ef1a017669e73e73ef1e6a03d9a71e73e73ef3a60169869f73ef1f69883869f1f1a600ebeff1e718018fcfce0059a7d7c68059c7dfc61671f7f1661c7dfc63c7d7ce3c7dfc63c79c7c7c698e9ef1ebf1ee00e1e71e71e1f1e1f1883875e71e73e71e1e001e1cfdc79d7b8807869d79cfbd6805e1a73f75879a01f969f69903f660e05d9f8000340003c000300002c060a80e0640a09d86050c099fbe64584fcd82104c7b4ab84b0920e04c7ab1d84c7a80104a4a4a4a4a4a4a4a4a4e06042069001017969869882fb73e71e6b801f661a71e75ef1a017669e73e73ef1e6a03d9a71e73e73ef3a60169869f73ef1f69883869f1f1a600ebeff1e718018fcfce0059a7d7c68059c7dfc61671f7f1661c7dfc63c7d7ce3c7dfc63c79c7c7c698e9ef1ebf1ee00e1e71e71e1f1e1f1883875e71e1f1e1e001e1cfdc79d7b8807869d79cfbd6805e1a73f75879a01f969f69903f660e05d8f8000340003c000300002c060a80e0640a09d86050c099d57aba84b55f180491178c0497320384e5ffe684c7a80104a4a4a4a4a4a4a4a4a4e068420690016ea905118e588e5c2069fd24f1876fdf1fa3933d68b70468178c2f4af7c535650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001cdb602080601880380380913d3903803d829020815114023df3007d020b04150620082a0a350c3f0e4a1054125f14691674187e1a891c931e9e20a822b324bd26c828d22add2ce72ef230fc33073511371c39263b313d3b3f464150435b45654770497a4b854d8f4f9a51a453af55b957c459ce5bd85de35fed61f86402660d68176a226c2c6e377041724c74567661786b7a767c807e8b809582a084aa86b588bf8aca8cd48edf90e992f494fe970999139b1e9d289f33a13da348a552a75da967ab72ad7caf87b191b39bb5a6b7b0b9bbbbc5bdd0bfdac1e5c3efc5fac804ca0fcc19ce24d02ed239d443d64ed858da63dc6dde78e082e28de497e6a2e8aceab7ecc1eeccf0d6f2e1f4ebf6f6f900fb0bfd15ffff01f802270259028102ae02d4030003340360039f03cb03e80438045e048c04be04e505150548057a059e05c705f3062e0656068206d1070b073a075f078f07fe088808c7092a0971098609aa09e10a140a3f0a800ac10ad80b000b310b680bde0bfe0c2f0c650c810cae0cd70d010d290d4b0d6b0d960db00dd40df30e190e4d0e720ea10ec60eec0f3d0f740fb50fd710281060109410bf11071127117111b111ff1219126812a212ed132d136213a413f5143f14a514f0151c154c157115ac15dc160a163a165b169416c016f31727174f17b317d9180b1851188518b618ef1933195c199019be19f01a281a541ab01afe1b5d1b8c1bd11c161ca36182659060269071060269071060269060a41808a41851809460070471241810283850a9c9ec6f74892011420690018180818480a6a029a8028088106202204188028184988184988049191c1808382868a9c9de71cb09b1cdff89301942069001980198039a20268811a49801849a01801c0186018118d41808382860a9ec6f7489c9202142069001102900390292292112212012284292112204212039211207901100190c1810383068a9ec6f7489102942069001069009c40260021009800840260063806380e1f8b41810302860a9c9cdd6db89203142069001090200e40809401940101100901140120920120140194110059009041810303060a9de71cb09103942069001106019060942140142116310014312239001023922136211607940920b920900f900900f9001541818404878a9c9104142069001120b90621060942922122922122900102192219011360390601410ec1808383070a9e3636309104942069001701e6180688680e68841c290680660a49a519e419a51801a01a51a01c01a118e0598019a099a039c039a0998099c1820404880a9c9a51590892051420690016200e200200e200200e20020020020020028425802580623802182e21856210c1808483080a9005942069001281628430028230028021806218361f88c1808382870a9006142069001024880392201640a0390282604c38c00802eb0428cb8028e30a38c02ca0a30630e30800800c380b0a00c380381d9cc1808483088c1a69d09a5159089c7ab1d89c3ae9309b51f1789a9c96069420690010120392110200e4081590110090114012092012014019400e41808303060a9c9107142069001a001a0120620204818224610118422022604622122122138f41808303058a9cdd6db89ec6f7489c93079420690010800c10a40228029010c00c01260449800808808a00810a088610861991c1808403070de71cb09a5b49789a92081420690011a200668801a2006688688418118210638461841f8bc1808303058a9b51f1789c92089420690011a019a09820066080984006610098400661001a01809a018e09a609860d9141810284050a9c9ec6f748920914206900109203921102901102900102102900102102922102900102102900102901102901120392179741808383868a9c91099420690011860f9829a11a649a11c21068061021060261221a098e09849a0d986110c1808403078a9d0ba9989d632930920a1420690010704702608404608402638063841f8841808302858a9e3636309b4b5350920a942069001940194108612039210a6384638800c68468c0588108038d41808402878c9a9ec6f748920b14206900110a4042901180106090601a611960196019e019c09a018c41808402878cdd6db89ec6f7489a920b94206900101060190e012219001221922390010239231401031062906010290e29060102906010214090290601060190e01841810404078a9c910c14206900104382478850240a418c40248c48a400648a488480e4884182648e41808383068a9c910c94206900199a200668841808c404310639210849a11b6019c11a0f8d41808383070a9ec6f7489cdd6db8920d1420690014c384c380ec94c80c94c82a00c1062300304188c02a00c14210914210800aa2c10210c80c90210c1aa98030e130e02a1f9dc1808503898b51f1788b51f1785a8a9acab2908ec6f748850d94206900126380663846006122180198488602619021068269021068071021460261021461fe087e1f95c1808503898a9ec6f7489d353530920e142069001028298018a600a90680641ab24a0492a0ac1286158bc1808382868c7ab1d89a9991109c9f2e1c789a940e9420690012e48a059220248860390310e2806314110e1140d906118bc1810403080a9c910f1420690011861186018841a01a2120aa0906006220aa0280da800d41808382070b9a18489ee78e409c6402109c9a940f942069001988180998818098808818059880881802021022005a0210220018808818059880881809881809988181fc2eaa01aaec20c2e30a006a30e4201c2e806ec205c060c0612841808405088a9f2e9da89d1e87589a1aa2f09bf549d180440549d1804d49d180480549d1804710142069001066f03ee1806e9ce81ee986e80e98ee80ee1c89ae00e1c2106b803b86a06638038690918e00ee1a8198e00e1a42463803b86a0663803a61093a05ba622e84e988ba0316038607bc032a32b30609b06b306a1b06134a1b40b4a3b20b0a1b405b06b300b0ab40fb0e0b0605bbc18306070c0a9a9a8188b099db84c09c99d34c6099d3d460961094206900101194039060390312090219011025922590090259229229009031221229229009031221001021900190219011060590609b41810484090a9c911114206900146026601e6981e614800812600e6204888008084206046285080a02128180188184a0602620498a1a814600661481aa1281801a0612a18018a20a18019881881811c059c0aac1818405080f8c99289e738a189da388489b71c8809c9a951194206900104408400e40a400640c404408640423900102580400239001023805002902902903120120086408e01011208a00860120192099205900792120c1818484888a9c9112142069001280e2180e28261f8341808282848a9012942069001362182300e29023902806318062140906019407920b8ac1810403078a9c911314206900112201a407a040880281222003a0408420e21280481a880691a800903e819141808482888a9c6402109c5379809c7cba5093139420690010181084006210019c00a018a09a0126d926026146026106600e680641a110c1810402880d3535309ec6f7489a921414206900188a4042900246921126a20206a20a06a212401a408d41808402070deb8ab89d6329309c9a93149420690012258027806290a20a0800a62888a10aa18800aaa0a0a10aa20a886a20a8c6089e038a058a0595c1810503098d3535309c96bf8fb09c9ecf56409a941514206900101a88a80a88a809a8808420aa021082801a802a8188aa8188ac0aa0a88a80a88a812a1f9641808502898a9c1a69d09ecd83309d0ba9989c7ab1d894159420690010201620423822380e1f84c1808382060a9016142069001680e6806886046886884181182106046700670bc1808302858a9d6e8f509983041092169420690010106090e60840240861260840240861081a80281a8382818dc1808282850a9eef2f509cdd6db8992b3c6093171420690012500e500e40c40248c404408e508e40240a40c4086408400488e508e50040c40440c400e500e5021f97c1818484088a9c911794206900111c199851805986019848a41811a4198098488641c50a49801840a68a418488e49a40a68a41848a68a418018408649848a68a41801848a49c488641809c51809a48a49801a0986019a49c01809801801a09a01c01a09a018098098098018098139809813e418285068a0aacaafe6f20a218142069001116010212294212294290314212210110e00b41808183040a9c91189420690010106090e60840240861260840240861081a80281a8382818dc1808282850a9eaf772099bca37098ea69c893191420690010900b901122121122120100122101102120100100122042120101100121120100390079011741810403078a9ec6f7489119942069001408039020243824380e1f85c1808382060a9d6e2770911a142069001102102100102102100102101102101100390090092012090014114011c1808302858a9ec6f748911a9420690018600e218110600e418019841a11841a09a039a00bc1808382060a9de71cb09c7cba50921b1420690010198018059841801801840229060060a4006380638c41808302058a9c0a61d09ec6f748921b94206900106600601661060060061008a418018290018e018e0f8cc1808302858a9c9ec6f748921c1420690010280628041801906241241d86c1808202848e9d0af89c9c1219209a931c942069001450065026438243816558065b82405e408408c1808582898a8a911d142069001012039201821211821229210a439811460041a019068d41808302858a1aa2f09c9cdd6db8921d9420690014806484408019020243804386c1808301858a9c911e142069001860841811821821060841a11a2106380e618ac1808381868a9d6329309c921e942069001a038a108400e210118e098e1186c1808382060a1aa2f09c9a921f1420690011840a058a418018498019849811a059a089c1808381870b51f1789f8f05509a921f94206900109c099c039821c019c21809a01848868268a4180196212602608498609e609241808502898a9a9259209c640210922014206900108400e210108400700210098e098e118941808382060b51f1789f764db89a922094206900128200ea0803aa2006a8812841a82c41a82a6029600c41808402070a9c9b55f18099bca3709c7cba50942114206900108840803902824884080390292090280e2900392039210d41808402078a9c912194206900101a039a01840860460841a49811849801a039a00c41808302058a9c9a2a1210922214206900167016701e60c600660c604400c0ac0a618ac0ac02418c782c79c03083b00b083b20b1e01b0eab0030b3007b0b3001b40bb411cc18205040a0a994b2e709fcd8211f9cf0b8b89bf060609c9522942069001010601940102140942122140942123100903142900902920102806290010611060906010e0192014117c1820304860a9c91231420690010d94079061122920192290e2192092212290312290090292290312290090239062192110293e01916095607906012010119009c41820505090a9c91239420690010120b94210210110210210014039417940394158ac1808383068a9c912414206900103a205a20fa02a001a02a00d886018860b8888c08888c098888c08888c0b8860188611c038a058a098e019e119e41a01c41986479a0198e4598e0d9a6099f418205858b0a9a9afe6f209c932494206900108a058a01886018860896089600840860884086088601886092281629409207920394019209900190019541820404878a9c912514206900103e280e300e2122822142390e29229162916211e211e2916292e01916010e0191609207906012c1818404880c9a91259420690012701663816638465816718860064006086638c61167580e1f8bc18085830a0a8a9991e1c8822614206900101a01028229001a11850860260851809a51a09a419801a51a09a419c0940394018611a09a11b609c01b601996098e0398e11c0598609f41828485088a9c99f9fba092269420690010c018c00a4081102103106090621407940f8a41808302860a9c9127142069001108680e688039021a039a21011029c11c29009029c11c29001a40861086418601228421468268050260048068268049a01a09c118e118e0a241818484888a9c9afe6f209227942069001018e118e01982398018239811821831801821831811823980182398119e01ae098419a018419801a098601986019941810503890a9fb504709c9228142069001121592094099401886682688601886682688601896089601982198098219803982980198298019009a059a090092604602604612110618066190059a059c121c1820485890a9a7c92289420690018e3f8fe3f8fe3f8fe3f83c18085830b8ff800009029142069001a0603a0612068a80481a2a002070c80081c3226a22a00206a22a26a26a00206a26a2498680081261a002041c804810720120603a060a141810484088a99fb80f09dc7760098b7a1b8932994206900112842803a842803a832812832812c420a80a1988280280ac03ac0a802c0bac01341808482888a9c9a5427409922fe309d45ff28942a14206900121fa403a0603a05220a2520120290690a5200a031488864a00a031488864a00a031290864a00242128809084206021601a16125609ec1810485090a9f75f6709c9bc20aa0932a94206900109009009003900100100590e03902390110310310010219021900103103101102390110010e0100190010010039009009009d41820305858a9c912b1420690010245844780e4886480488e4844896509e48048a488640c4886418841896418c480417e092c18086030b0a99964e78912b942069001112039205902901102921102194239001031029021902922590279225902790010239225900902920143100192059409b41810304880fcd82109a9c922c142069001b9060594110219001903100902390090239225900902392259009031021221902101103100902192110e1106010e010012092010110092090110012039011011009012741828485888a9c912c9420690019a059a0198018498019849811a4198098419801c428498298428498218098498019849801a881a80a881a812960a9611c41808483888a994b2e709e4901009c9cf0b8b8942d1420690010198601986079829a11a408601e608518098508601621468261421805884886826102102180588488682688408680e608498019a41809a01a0186039a01a09809a018079a0981180980d9803980180f98079817b1418285060a0a99f9fba09c922d94206900111a21811c039c29809a21c09a31a09a318631c09c219a609a601a51809851c09a51809851a019a41a11841c01986039c099a09a0d9a019a03a141820485888a9c99bca370922e1420690011407940142100392211e0390e01021203902120902120390212112079209141808403078a9c912e94206900102688801a221890c604318839a1106a2123601a41220f8cc1808403070a9ec6f7489b55f1809ccf2a80932f1420690010e1f9a404690098290098290098018e018e118ac1808283060a9c9bead708922f94206900102207a4020610220018881062261089089089062002061262261262012060a0603a201a211641808383070a9dee9f389c8d96b89c9330142069001920592019221211221201431001431223900102390010212e2100920b920900f9001441808403878a9c91309420690012184006218402700670060460260460060060066006046016601e1f90c1808303860a9c8d96b89c923114206900148848848122201088184200206221226201206846a003a4024110c1808382868a9f27a7a89c8d96b89c9331942069001070470421001884046182618641808301858a9e36363098d1ac5892321420690010818268084220a0e0206089009102200206106200206084201240a06a00da2113c1808383068a9dfc3c389d5b13109f6bf5189332942069001014110601021401029201031009031229001902922100590210010099001241808303060a9c91331420690011a019a11820066081182006608118400661009a01809a0180186098609a019a139341810304058a9e1f84e89c92339420690010808c10a40220020029010c008088012604498008108108008108038c10c113c1808402878de71cb09a5b49789a9234142069001018200e608018210019821001a01811a01801a039a00d41808302058a9c9bead708923494206900121f89010038901003c0008480e212140828020e4001bb020042e00c20e40c210a9020631028840099000840e02a01030e4001c00dc001a1c1810503890e9d44a89a5159089c1a69d09c5291f89b7201889d4258f09c3ae9309feffe589a983514206900101a059a11a21068268841a018601986178941808382070a9d964f1899420b70923594206900104801e801621203884848008184818280089c019c880800682668080fc1808402880a9b1cdff89c99c0817093361420690010a205a212021880068086200202106a00a02106a261a0661a27200200207200a402012407a012009a003a005a007a009c41818384870a9c9ccf2a809a5b49789336942069001221001884016480648066200f988188182858089a80281889805a00a00390c1818383070c9e46cf589a9cfd1d5893371420690010b920192019029009029009021029221900102192210290090290090290019201920b9441810383868a9c913794206900110e110e01221900106292239001062906310010212292212290014310e2120102390010e09021920b90e01841810404078a9c9138142069001429810a6006c00518094600830ab2832128ca0a300a0ca8c200316800e82a0a0a300195c1818482880feffe589fffe4b09de4f3b09c5379809f761cd09a953894206900108901224008888028888906200a04188382818b41808282050a9cf46f509c9f9e7ee09339142069001221001884016480648066200f988188182858089a80281889805a00a00390c1810403070c9e46cf589a9cfd1d5893399420690010a001a003a220288801a04188008106220200221220a0118e41808382860a9d964f189b1cdff89c933a1420690018180818480a6a029a8028088106202204188028184988184988049191c1808382868a9c9ceed64099bca370933a9420690013e504e40c48365086404502438c40240c40050840a40250c4004584418c03901142102900d91611901597c1818485088a9c913b14206900110280e2900102184219229020421029221842190010280e2901120392179141808383868a9c913b942069001039c079c099a118039811a0398110298118290118118110219801821901180180190290218018210290019a019021980182190019a0390280700290039c0392604612039a099e0399e0aa418106048b8f5818189a9c923c142069001114039060590310110219001902390010259011029029001029029211221900102192010010014290010312090110014110601001900100d9001003900d9001a541820484898a9c913c94206900138ac84c0ac816c08932030224c82e02224418c00224418c02e02c22418830a30890620a00e80ab0418832032418830abaa82c184c380ea3418085030a0b31c9889b08e2809e5edfe09acab2909fce6f609b01b1b09f193550963d14206900102200280628020261000a058a0106006100d906047016705e1f8ec1808403080ff800009eb1d0009a923d9420690010920794110300e4086010238440a670a09029c298e202298e2196088658869268221849c21a49a11849c018e0198e11c059c09d41818405080a9c9ff40ed0923e1420690010920794110300e4086010238440a670a09029c298e202298e2196088658869268221849c21a49a11849c018e0198e11c059c09d41818405080a9c9aad6ec8923e9420690010108158805881588484408138a484408138a502408138a500488118a50248a0f8a51c4b403b903901066190c40613901b051864408a90300c282911070064282b0b8c42ac4730019020ac4cc0ac4c38302b01b0040a40ed00703b8140ee02713803c405ba418105878b0a9cf0b8b89a80a1409c3abaa89c4840009ff800009805b8009faee000973f142069001b48b53ae64e4e02786d9b05574ff7238342284e3134a855493bc45f0df430738000000000000000000000000000000000000000000000000000000000000000000000020ee602080601880380380913d3903803d829020815114023df30061025304a506f709490b9c0dee1040129214e5173719891bdb1e2d208022d22524277629c92c1b2e6d30bf3312356437b63a083c5a3ead40ff435145a347f64a484c9a4eec513f539155e358355a875cda5f2c617e63d0662368756ac76d196f6c71be7410766278b47b077d597fab81fd845086a288f48b468d988feb923d948f96e199349b869dd8a02aa27da4cfa721a973abc5ae18b06ab2bcb50eb761b9b3bc05be57c0aac2fcc54ec7a0c9f2cc45ce97d0e9d33bd58ed7e0da32dc84ded7ffff0188021502360260029002ab02ca034a039803b503d503ef040a04240441048a04e5059b05e20600063b065806a0073d07a607ed083e085b087808a608ba08d908fd091909310967098209a209b50a0c0a200a470a8a0afc0b300b720bb90c7b0f6c101c10d011b21218126b12d51306133e137413a113e41425159416a316fb17ca181218211839186d18ba18d01972198719a719bd19d11a0e1a4d1a851ac61b101b581bfb1cf01d381d841dc31df61e581e811e9e1ed51f101f641ff92020203a20b6079c1598408418119a21070066806688418018601a019a21060066384a8841813b88286056c28c2013b2ea211b0a30ea00fb0ab0a220fa8e30a30a046c28d2811b0a38c288046c38c85ea3415b8ab817b0a85ea38c85ea38c056800a3019b0a066e3015b0030e06ec380fbd418a020c890cdd6db8dec6f748dcde363630dadb51f178dc1a69d0d6012420690011850240a518518004c1808201830506bbddd06d4258f06d496ab06201a420690012100198210802818210800898222020600a41808182830a6f6bf5186a80a1406d496ab0630224206900158c0d8a40a098a5080988418a058a488608a00a40c08a00a0086038960b8c0f88179241828385070c6a6102a4206900109009031001400441808181828f75f6706d496ab061032420690010188e038a10a10a038a00a05880880b8a0b8941820303058a6003a42069001118e0d906582e70c602e70221a099c08a602670421a0598e11c0398640066a409ac01e688884c38079a8006c3815b0a056a3815b0e04ec3813b215b0e056c056e2815b8a056a856a3015a8c056a3015aa15b8c056e3215ba17b817b813b2418a018f080ec6f748dcdd6db8dcdf761cd1b6ada2941e0da515908d60424206900107e72001c179a01a8186139a11881801a039403980a001881a0180188e09c09c8006007026806584818800e658063a0119c039a0b9dc18107040c0b51f178babd4258f06c71f8d06304a42069001010c0390e110039000441808281848d496ab06f6bf5186105242069001c00c01841801801801c1386c1820104020a6f6bf5186d496ab06205a420690018098c098a018810a08a01886006c1808282848a600624206900144180e408640440964004026406c1808282050a6c6106a42069001114039031011211200541808281848a6c2931306107242069001042380e284284280e280281e286c1810302058deada986007a42069001019960d984598099849c49a0792608608612681641829829849a019260a60a61460449ae518090681e6926026836690605e6866686661f41828506088a6fcd8211f6c620824206900105a1e13a06b83681b6099266780e40a691a81a1102b9c91a1102b98681c88040ae6ba2010299a681880040a66da0010299a6880e219066383e408619902186e50461fa1418385880a8b96fcd8211f6b9bfcd8211fb308a420690016687668266866682e705e6836685e682e7056702e7056702e7056702e6184661826638466381e638366781e6582e678166886381e6981660a63816638a700660c6784678a68468c6990e638870260c679471470a68260c65926792708618c67916619070a70c6392859269261221c298e423641a5182186218e423641849c218629864236418e298098298e4226418e318099e0926099e039c19986150c183078c8e8fcd8211f9d01c8809a9d49e1e09309242069001e2b82e2f81e3380e2180238021806304304304300e2006218230423843022182e2180282300e3022002842b84306e281623816280e200e200e21dc1820506898a6009a420690016382608608600694685c1808201838c2931306d92f3d06c620a24206900107901394119407921141120106010e010e0920590094090088110012019000c01207940140994014019741810405078a6d92f3d1b610aa4206900142380630428020020162581e206c1810302058f012098600b242069001704e60865a4039821a6904610602880e882a3012009a00b0a056c2813b213b215b017b017b21595c1840306080fd7d7d0dda5a5a0dd4258f06adf761cd0df5c5090d50ba42069001f1b817036f000f03170090b49310007031700870329310007030f0886640c24c4001c0c22cc065c0c3c001c0c22c4041849d0b08b1000703501261261c0c22c4001c0d41e740c22c4001c08c2cc16640d4003c08b1130f131031000ec3cb31f0b30006ea96f350b5004e286f28c584cc001bc07b403b1001e1fc5c18386080c0a6abfdf91b06fdf91b0bc7cba506b5068686c6fb50470670c2420690013a0e1da061a219a065a417a0661a217a22202226a017a229091a805e80852462215a0210681c8006882689489c8828188f9489c819be899c8008187fa00a26ba1e6a212267a007a403a261a419a1615ab418284880c0aafdf91b0aecabb18ad08a0a0a30ca420690011415940920120f9160120920b92019201209210c0120590092090e010601900100790661403940d980181f981180b9a418106040b8c1a69d06fd680b06c3ae930620d2420690012413a060a20220f90838062009409908848806200a048231281803a00a20a05200204206006800601e6a2222600e81a0d880081f881080ba1418106040b8d4258f06f8c11406c1219206a630da420690014258062002806300200281e280203e208c1810382068a600e24206900109010c010e01001000541808182028d496ab06a80a140610ea42069001e6382e688408681668c40c68468864086682613e6007984e60dc1818403878a6c28d0d06e394948620f242069001223822b81c1808281048c121920600fa4206900101c01031260861001c00641808182028a6a1138e86d496ab06210242069001019405902390110210e21001207940d8841810302858f6bf5186e2344306110a420690018c09211201201200541808201838c1219206c2931306111242069001a08c08a00a038a10c00c086c1808301858a6011a42069001660849801aa801e82a028818081a812c12c12a07aa00cc1810382868c2b29e06b51f1786d92f3d06b6071686c2931306412242069001022384284280280e301e205c1810282048db0d8686012a4206900144181648a504488e482409e41826407c1810302858c2931306c61132420690010805880096002c1808281040a6013a420690015986179a41c1398518e0d9a41a60b98498118e07986079a40166106022184610600e61068a08a01c41811849ce41809841841a0598419641860b99641817980981da4418205868a0ec6f7486c6d92f3d062142420690013004381c1808181028a6c2931306114a420690010112200e418801906204458809162005044881194118b41808284848a6adadad861152420690010b9061b92615936119460d95e0990e0391605906099160190e0b90e01906108e110e09061392e179261792619940121b92015418206070b8c1219206a6115a4206900116692690603e619269070266990712079c41841c41a41a039c418e49a41a0398e41ae400e61906b9061011a418603996400712681e71401c41c408e418018641841c09841c41811841841a4181598418e159c01a199a0181b980981b980981fb6c18405888a8c6ec6f7486a6216242069001e4b8265380e4380e43844182e4182503e5024806238064385e4185e4185e506e486e40fc1820505898a5159086a6116a42069001a24022382422120702e918020703e89802260466206a0605662062217a061798886e886e886e6201d9741850505898a5159086b51f1786c1219206a63172420690011e705e658467146836612619260266106792601677806739068263826690602703e6180704238066584e658566185e706e618c1820507098fce7a106fe780b06a6217a42069001170c87003f0ca94a0ba884a740848802704a6a86a92c007ca42a628610849001704861062862a62b0806a41221018a1902841901108504a81842862d1110050188c2a98aa0642a030a3098828648a2310302102063060cc4a8c0c030212a0c10ec4a621030021029330f3188b002104bea4a840c2104cc00ec292a1240c41284e80e833210ca03b803803cb04a17c8619ca1bca1ddcc183050a898b2211186a1130706a6e1c0a306c7ab1d86d1b71f06d6329306c2931306d49e1e068182420690011603683601f60276027600f6016516397181594580d80580da01a805c03db45942961961940085945802961965162968145aa1945805d9558651618a00a50a5aa58658650a5a6536286516a801db419618e5865862962b4294196d0a39619750a58658a5801d9419629458658629619458a516294d8a1b459458a586d82581594194a94196194194d8a5165362a6537294996196056994a94296194594d8a51619458a5065955b498251605654a5945b4195594a941949b4595594d8229603639650e29629718a1945b49b45865a6516194d8a516007652a38a5865942b458a5a6d0a5865b458ad2ad1605651650a58a58652ad1650a58659458a5c65aa194a94d80d9558651618a50a50a5942961961942969b458a194d8a516816d0658651619618a58ad0a5065b42b619750a5ca5c0d9419629458658629619458a516294d8a1b459458a5a6582581594194a94196194194d8a5165362a6537294996196836994a94296194594d8a51619458a5065955b498251605654a5945b4195594a9419b4595594d82296007650658a51653699458653653619499529619651600f65362b6114d94196556516d0651650a58a5955805d95296d066516516516d06d2b54e5807da852a5941149969965162941943a953960276994a96d36d1653629459418a516d1619682f621419429411458653650a59458650a5b499683f654ad8851653650a5945862945949945813d9419629621629651619699650a51651619684f6506594294d94216d1651653652658e5815d94ab459458818851651653629618e5817daa58a5562065943ad4396067458a5945b45885b45945ca594581bd162965168168160161a945945819d945942945cc38161d1651606765163945a05b158605945945819d941d80dd25c03d94581bdb45803cc05d94da17dd45801c814807d16867651606f70676877651606f407f607e1fd80981be01848994138fffe4b06fce7a106b51f1786f764db86fcd82106c2931306d0ba9986e9d0af86d3331686d6329306ebd91c06a18a4206900107e1f87e806e1fa41787e8b0805e1fa2c201787e8b0884e1fa4c221387e8b4804e1fa0d221387e8b0830887ea180ba0c206c200b9c05a8609a0c206c2207a9612a0aa07a412403a861280aa01aa05a007a011aa816a00a016a1c038a50472a07ac07aa61a8600e61ac12c0aa0a86128e6aa01aa380ea006a82a02a016a384b026a82a1806a01e1fa860ac02a1787eb04e1fccc183098a930b51f1786a1138e88a6a8a6920a868b85830651924206900117ace0b87ebd8161fa8ecda96107eb34230e2b06a3821faac88c18cc18acac087ea30e2bb4232a821fa8d0d6c1a8087ea3239b4a021fa8c0c08a608cc2a107ea0a01896038aa001f9069007a860792604401e49801062049c090882e70049881849888041a4188128128808920a2418291849801849a0146204008980188848848900909029046220906200d041820b87160d02c1b86c6200f06a80a1406d02c1b8dc6200f0da80a140dcdad1e06619a4206900103a812801a811a842c42a0284280a807a8290a18498a184a862807a829a649ca016a18479c41889803a82106619460892812a4198e5182a4a02a084198e42870a8a8088439851aa1c2a4a88418518a126aa68a92a45a851ca1a2a4a94690a1066a870892a5184a8419aa10724a946284284398a10628624a9462847a8498a1892c498a106a192a98928028498a11ea90a1a92802849a028641aa60892802849aa82b10a9a222a02a0a42a03a8428724a00e62807aa122a816a026a00682807a80187ea0061fa817f84183060c8b8a6d7e1f406f374f706c6e66cf88641a24206900103a0620600e898800e898800e898880e81a801681822003a260881801a0220220600681c88489881822060280861a20a2620720602818818680289960a07107200206946a00a063a001a002212e41810289050ec6f7486c6c2931306e4696e0631aa420690014e1f98819c15a021a0704e622322683e6a26601e9116819a07a04da07026812681860ba04244a061836898689c0fa06b84e81c1fa0119bc18383868b08000008afcd8211faa8188e0af28a0a0631b24206900102e6186660849a179840849a0ba0e612212620601a0a39a51aa1a00a0a79a41aa3a0020ab9ca7a2ad98a9a2ab9ca7a2a7996a5a2a59a6a3a0020a39aeb200a0a39aeaa001a0a399eaa005a0a0761fa8c18305080a8fcd8211f8b98a8ecabb188ecbf438841ba4206900107920b9021205923100590219201902590014e2d900122790019221900790611041820205060a6fdf91b0611c242069001016483e40a402648864816402482407e6044846008180200900901206046016620093c1820384070fb504706f28a0a06a6c631ca420690010901080d9430450440048a0190010039228050040164380e1f921190090119017901790079441830385878a6afe6f20911d242069001400e401e4844844844380e2101188400482640848a402640240a0d8fc1820503870a6fcd8211f611da420690011e858368886901e80a68016878c80068926900800814691853a00984b81e611e0d9a4183663920d996119c1395c1830386888aaacfcd8211faa8188e0631e242069001093e05926b9203906f92110739209068a6d9201068c6d90010688739265886b92638c6980419621a60b881b880d9841820486090fcd8211fab9aaa21ea42069001019ba61587ee44e406f0361fc0ee41ee40e00e1fb970bb07b9038107ef40c3b0bb0b90b2ec0e001fc2e310bb0b905b8c3d0381dc4cc2ec4e40e406f40c42e06713113901b905b90390390b817b901b903b903905b907b815b90b907b901b913901b903103813c4e41ee406e436c40e83ee44ec06e42e456e310380fb901b907bb13905b90bb0380fb913b91390db10380fb8c446e44e436c3a0fb8c466e40ee40ee04ee42f1f856ec36e2064426c781ec5c26e2164416e7b203b107b1059084069406ec1ec84c42ecc068c0e8c4e43e602c436cc06838e840f416640640e4403103901913913103b90b9701b863801c06e42e4009b0b9078b13d01b863a03990b9018039b0bb13822c2416e1b039001713807c06c4e88a388e198e42e42059903903807c2738008a5880ba040eb007c4040e056228e2016c81663a6400c0605eb021f80b401828b0e958c6e5edfe06f4724886fcd8211d6fcd8211f6cdd6db86f5c5091b6f5c50919671f2420690010fb86a0061fa8f2ae387ea3a6abc1bbdea056e1a8f1a811a8e28e5a8ed83ee5aae28f28e1a8e82eea8e1aae3a8e2aea8e2807baa38eab8a3ca38abaa1816ea8ea8eaae28f28e2ce28f2801bca3aab8ab8abaa38b38a38a38a006f28eaae2ae2aea8e2ceaae28e04f28eaae2ae2ce286eacea813aab8a5b8a9bab3aa04eaae296e29eeacf006eacbfbc03b8b3861a8ef1ab3c05baabc6bba6aaf01ee39261261261261062af026e390612612612638a1ba13801bc61b8e63a86e84e180e798234218eb80e80f00ea4e88c388aa06e382e5a0e230e221ee184e3a1ed22ee382e3a7ef00ee1a7ef02e1fb80180840184078e0f8a6fcd8211d691101a0691101a0388850006c6f5c50919661fa4206900101a842842807a821882841803a8228c38c28428128218c3cc28818028418c38ec28828130e3b007c0f400bc4039b41820304068f96a469b6fcd8211d6d63293196a694141406888500069e1e1e06991919067202420690012ea80e1fac0187ea5801faae1dabe17abe42a11ad642a0ba964a8e42a4a809a8e529642a4aa03a86429e52a42842c01aae42a4a842a52c0a86428e4aa41aa4ac02ce42a41aa42a642842de429e42de42a429e429e4a9e42a429642a642a4a9642964aa642a4ac52c02a42842de52c028642a0096028e4a8602865026af82a190a2fe0aa621ace128688881a8e928e12c90883aa85ac01ac818891ac03aa9baa05aa9ba809a899aa09a899a80b87e1f87e1fdcc18506908d8a8188e06a8188e03ecd03306c7ab1d86a6420a42069001390e0790663920190710659211061906590110738441ce110618c658241a29a219c09070c70a0788708688601e21a609886785e1f9c41828307080fcd8211f6b96a62212420690010238041808100828a6021a420690018a098c00a088058a018800641818183828a60222420690014f03e3042042006800e900641a03980598089c1828184838a0a0a086a6a0a08006c7ab1d86f6e6d786deb92006c6622a420690010e41a4182641821986400e688608661901182b98610c66900182390e3186279021996259021986010608e40c6180641a439a0d90e1394079bc18284860889d9f9d06a6aa2ca9062232420690018a008038c138c00810541820183828a6023a4206900105e503e4181e40a402e40c401e48a401e40c402e40c400e40c403e40c4044086403e40864024086404640c4024086400e401640864004086400402408402402408e488648848c488400408e488640c40c40c488e488640a478c408e40040c418164188e4004086403e48c40440848240164044884006502402402402404500e40064016400e40464004804001f900900fd1c18286898c8a8fa79660812424206900102043002b8030420441810182828a6024a4206900114078848063121086458c40448a400648840a41818203840a6c6125242069001b8a07886038a089e08441808302050a6025a42069001086118a01881b82c1828184028a60262420690010991e0d90279009902b9005902f90019031901103390015629231902900903590110319003902b920792e039641820386090a6d0ba9986126a42069001168180e61a022022209843a222022009845a222012245a20a04a24382810e81201a04581e810e09a04801f97c1830205868aaaafcd8211fac632724206900103a409a422401a440c4240a0609e6200206906a06906a5e0fa003a00200ba0120019341820384868a6e2344306c6f8de5186327a42069001b8847846212e0f884d836219e4181e292669260062946704210e692e602210e61160b8a498458462984981d9a0f97418283858a8aafcd8211fab9a22824206900126885e80a804e88a884680868026604810680460462c802882800a98098b02eb1ab0068806b180aa120601aa019c1820484890f5a20186a6bf060606e2344306f581af06428a42069001b9061b92615936119460d95e0990e0391605906099160190e090e090e019060f90e09061392e058c0592603881080392619940121b92018418286070b8a69e1e1e0612924206900160261f9820161f9c0387e618366182e638266981e21801841803906d80e60860241803906d90018868241c0907390088682610680418e0398e40021c01841a0186099960086806106784704638021a01841960f98e2106006784e63906026385e6390098e1798e4027106066619011a406e618066901b9860398406e6106016686e6106016686e61009981b9801cb4185070b0e0a6a8a6a986c23f4386229a420690010d8c1b88808c0a80562a8c18880368088b1e282e2b2a34a3280809a0234830e828d00e2a0ca0a30ea22c20c006220ca0c20c1a0d20d02ca2c5a2c20ca0d02c1a8c20ca2a30a348b00a0d28c288316a30832832834830830e8328289328b0a20ca8c1a88348308b0683282ac1b7ea30ea31e832a30a34a3068b0e832a30eab2a3068300308306a34e0a2d28cba8d20034a30603b16a30034ab209c132a320b4a30830010e020c20c20c28030a34020c84d20030a30a00ca8c048308008308006c28c00c1856d02c866c82c06ec04c06ec04c001fff4183060e8b0c6ececec86f5f5f586ecabb186c7c7c786ebebeb8652a2420690011e705e6584670c683660a618a6026608678a60167780673886826381e708602703e618070441c40066584e658566185e706e619c1828507098a6ad892206aaaaaa8622aa420690017e918020685e8808988184e884818800880e300e802600818880800643829029180200226028808584620600e8580839811a403a20b9ec18207040c0c6b4b53506c23f4386a632b2420690013a266026919803a0e03a066049180ba46028980fa40a0604e898880e40c400e8185e9066906e886e81541828505898ec6f7486c6a6b990af0632ba420690016401e500e408500640848811021421009021062024588014110210119c111c1808285048bcb93c86c6e05ce00622c24206900101fb0b00e2a17acc28eb0a84ea3012ae00c28038c03a80a8030a38a00a846382eb00b0b02e00c280a8e10a82a84ab003b0b384004286c04ea3803ba0ba4418107040c0d1330606efb89306c7ab1d86f3d66406e9384186a6c997a18662ca4206900111c0398118007e488e4804784e700e604607e1f8a41830286848a6c6200f06d334a98622d24206900110c08a0788600860880f880388058808841820184038a602da420690010e7041f98e059a40c41a1184b980984b98018519649a418079841805980f980180392c1820385068a6a80a1406e62f3f8622e2420690014a380ea1829062812867a80286a8e6ac07aa01ac07a80a0a016a02828110c1820304058a6ee45b51d6bf060606e62f3f86e648d18642ea4206900101e8b83e29a20b8848848840a901e2122122122a411a2b9021022009a8d88e8006276098878a898462062a36019888883846620224285e304e1f87e1fa0c18484078a0fcd8211fabea61b19ac6aa32f2420690012e8001fa41b98898880803e8006227206a00da06a063a06a209a06206fa002001a077a20a002079a00a00207b80899609a0398e898601a9611c898612c21a809c89c0ac418ca026a0020602a926a826a0020602a106a392a02620020600a90b00ea10a02602802b02c80ea826a04c026a04ec821fb00fc4c183058a0b0fd428006a6eb1d0006ff800006c6ed801d0652fa420690019a11840860061229a219a21a218018098138b41820184030a6f6bf5186c10a0a062302420690018a108088008018a018a01881d8741820184030a6030a4206900101e844803687c007a4e307001f0386b08b084005a0610624084007a0418b13809942c2e20e01e540c40a38cb887b5028634f0206327034e026b2703300281aa30f032e40120e286c3c003a0a3b2e4009c1e01aec1830208080a9d3535309cacb4b09e3e3e389b4b53509e3636309c2931309e48f0f09731242069001ccfff0b68fdf261ddc4b1ca73697881a6b53f356d35bf93e9961efd2665cb9bd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005235602080601880380380913d3903803d829020815114023df3007901db03b60591076b09460b210cfc0ed610b1128c14671641181c19f71bd11dac1f872162233c251726f228cd2aa72c822e5d3037321233ed35c837a2397d3b583d333f0d40e842c3449d467848534a2e4c084de34fbe51995373554e572959035ade5cb95e94606e6249642465ff67d969b46b8f6d696f44711f72fa74d476af788a7a657c3f7e1a7ff581cf83aa85858760893a8b158cf08ecb90a59280945b9635981099eb9bc6a49aa675a850aa2aac05ade0afbbb195b370b54bb725b900badbbcb6be90c06bc246c421c5fbc7d6c9b1cb8bcd66cf41d11cd2f6d4d1d6acd887da61dc3cde17dff1e1cce3a7fe25ffff01e8024c02e70310038403ce047c050c05b705e7063a06bc0817085a09a50a050ac30b710bea0ce20d220da40e890edd0fa010b31199121e135f1463168716be17cf189c18d4191e1a111a6e1ae11b3e1e421f0320a0215b21d22208224b241724ea26c6270627782884297f2b842bc12d0a2d892e522f1e30ae314631d5335434c2355a35c136053650369a36d937ac37f5385e38c13931397239ac39e03a4d3a8e3b103b923c1b3ce83d523e3a3ed63f75400140a940f841594208424a42e64390443a44f645e046f3479f4814485e499d49f54a604af74b644bcb4c5c4cdb4d5a4dd74e454e894ed74f7850a1512151cd51fd0187e20161f88108007e2842001f88018a0081b88018a008198a018a008198c10960080d8800c00b6098800e610801896018a600800a08a608800a3f84218fe058ee08c038ee098a00c00a00800a1080988078801880bae418287088d0a700134206900101920b8a601e483e2180592603e218400640a403e298018a604e6121086056212092210139a48040a1590694610159841a498179a21a418179841841841a1798641a15886190704e41864184180f98018418e41a01070060261906107107106106f90098641a41c6099e418e4196118649964986039c64186079be41a0b9c6119a605c84183060c0b0fe780b07fffe4b07fce7a107201b420690010620362022016282280e2022002006282200282284202200284204290c1830283858a70023420690014406e4024185e400488405e41884856212090e11884842121188488488438040040240040050220221221060106210008018848841884188480e210210e2142140392210e211e200640809020221209020020264080922024080d9020240815b7c18385070b0fce7a107fefd6687102b420690010101b921b9219906079007906059021003916039021003920102121142101140902126210e112213e21001922926212059029162100d916079dc1828506098a79e1e1e0710334206900141f98e03986199c4180996199c41a019619986419e1b9c61b9a418641861b9c41c41c1f9a418641a1f9c41c41a1f9c41801841a1d98e09861d98e11c1d986019c1f8a600e287e3006307e60a018a607670167066618166185e618166185661826690683e710602671060366190602e7106026619060366581e710683e63816638567106846190605e7126590606e619065801f99e0fcbc182878e8e8fce7a107fefd6687a5159087203b42069001e48564080b92205640a0794205640a0794198c039420662920192286629409428662906014286629060142866311e2866311e2866311e28663116306631162185631263101190310602472567240a467a066ba412469a26ba203a269a269a403a467a269a207a465a267a20ba461a0661a40fa6615a0e0a060bbec183070c0e0a7a5159087a7a51590873043420690011c0187e700e1f9a21a107e21c0187e6106841f9841a107e6106841f9841a107e6106841f9841a107e692107e7100187e6900187e6900187e6900187e6900187e6900187e6900187e690199c0398406e680e610018139801a039860180b9a41c039c01a079809841c0598611801809809841a079864006806026004186099a48068068041841c0b9a4186418e41a0f996419e159b605d1c182058e8d0b51f1787c1a69d07a7204b42069001a1b886178a6118c60988e08ae0189610b6088e018be008e058d6098c60d8ae1788e078ec18285858a8a70053420690014066402406640248564804184649846498465080140f9062004183641822140d942044381e212200e50805885080388508404438805884d880b8a50848805a1c18185070a0d3535307b4b53507105b4206900102422011a2622011a2622011a2e20468b8811a2e204681888a7e2229f888a7e2229f888a7e2229f8897a7e9fa7e9fa7ea26ea3a6ea5a5eab9891aa66aa8da8602a728687a8e0a86a9685a8e09aaba2a580662ae429e03ab6428e07ab642a0faa609aec182060e8b0c1219207c1219203de71cb07c7ab1d87c7ab1d874063420690012006202206e2006200200628020562022006200200e20020020462002802022002042002002002046200280202200282200200200203e280280200280282202280203e200282200204280280200283e20020023806280300283e30028028062802583e300280280e2002583e20030028162002003046200300280202200300284e200300280202200300284e2780284278562002180200e2385e2380281621866280301e306e23816202286e21842042386e302280e218762822042043076238430030762842006238762381e307640a0d88485640040a059001884826400e4004180e4388481e48064804780e4382484402480400418064824782404402402438164024024380480558064004824397e0192117e1140792016e03921106097603920900192092090601211201900920592092010010092112112079411009009007900190079009901101380bc01840913108a7a3106b4206900141f920941b9060141b94210e179062142101794200418817906094210139420065081392210039413902101787e1f98c18086858c8b4b53507cbcbcb87107342069001190090199011803880122101792600680e418c139000851a01906285640848869001984186621021060190e205e50848066004804081990e20460840a408198a43826120084066290210008600610214285e20048a68041a41881788e4398018408408178c45986506e212210661001061b88419a418400418a1788e6191e2056200508418e508405628040a488712310158c408488018018010e2056292210008710e210138c419a09840841a010138800849c11a41a4184080f8c01271009063804080d91e21061009c4588098840800a419801906122100122016290210621260064180106802103042190688518400649a218212e214688710059063902906290608692610010059068841a21840848a694610600402e71201c2102106926006900f98629c11065901788618166880b80b201830890100d6329307a5159087c1219207207b4206900101187e20420261f8a10a0587e280e2841f8c10a08c108138860589648028428228040960589640a6008640a6058c48ce408e0988650be012238163004804002984502218428164042180e40048421a941828905908c7fe780b0710834206900105921b87e4080d87e400e40a0987e500e40c1b9403906020640850565084045084a26a050841826508640248c4008186508e50448964188e400818645886482408e4388e480818e40c50c40240c50ae40481864886508498ae50489c81025942922f9403a26a048c3f9407a26224883f940da0650ee484e83942f90e15a0620e50c4986e818838250c4821fa26206019429061fa06226200592e1ba26a21587e898801e1fd841860a8a930bc20aa07d92f3d07a7a8188b07308b42069001680461fa009a06200d87e818801e6906200787e81c800e81c41880061fa065a00199e800685e68081a6802819e8007100b9261a2639062062001ae218e4016419629864188028988996298e40064196298641a01988028196219e11065a021864188006804818e800819e01065a002063a00da061a00a0679061a212061a00da272012467a205a0704681a801e8782e904e88561fd0c1828b07150a7f5e29807fffe4607983041073093420690011b9820766080591601926080a04d8251a2008166608020599820061666080185998200616e20055984204805598022400612e61202040091261160206100204048184204a06100a240280481802060281812007a012012017a017b6418505088a0e0b21b994f8c9929b4fcd8211f4d4258f194309b42069001fa061ba42a415a23202a211a23202a02a00da225a03220ba02da022009a22ba02a207a035a007a02da422007a029a212207a027a213a027a015a025a017a025a017a025a017a025a00f87e1f87e1f87e1f87e1f87e1f87e1fa86028601a8e028e4ac4a801a852c42a0284a852a0aa41a84a80a84a841aa02843a842801a847a802847a803a845ac45a807a845a845a80baa4da80fad609aa62863a861aa05aa6aa72c61aa01aa728028602863a812a61a805a863a812863a805a863a812863a805a863a812863a805a861aa12a72809a86aa03aa62a0ba862807ac0dac176418706178b8a7a1f5a20187f8c99287f8c9928140a342069001ba211a00a20a207a20a060ba417a417a405a011a00a011a202211a00a011a20240fa20a2059441828806080a9a42607f5c509197fcd8211f7bb730ab420690011f87e1fa048e64016814399005a050e6401681063590800e8105fa003a0417e800e810696e800e81069066392680068127146394619080068127146916619080068166619080068f91e710800681b6859168006819c683908026839c68056819a6807689801f87e1fb4c185068a8d8a7c7cba507fdf91b07e1dd1b0330b34206900106e63841f982198e1d9827981d9825981f9825981f982598007e60866021f982198107e60a600e1f982180387e608600e1f982180387e608600e1f982180387e608600e1f982180187e60a6041f98318107e3180998204621980998283e3180d98282e21980d982180e239807a2098339807a04a00982f9809a05200182b9c09a041a06896694801e811e65916801e817e80168156810e8016891e8106810e80268906810e810e8036890810e80081068046810e804812804e810e8006884e810e8001fa0522087e812800e1fa21bebc18807138d8a7a4ebb98707f28a0a0730bb420690010686e638566983e6906b826612618067806690638469886906380e69061886781e7106886190602e6388710603e6b8666001f9861b9809a159c11a1398119f418505878a8a799191907fcd8211f720c34206900107e9041fa06a0087e81c8001fa061a0007e81c8021fa06a0087e81a807688081a807e89c807e818808887e81880a807e81880a807e81a808807e81c884805e81868028188056818680081a804e818e80081a804e818e8985200fa065a243a209a065a002052052401a067a00204a0610620520667a00a04a0498818681c81061a00a04a052061a072041c8006890681841a810720418801e9108126a041c810803e879061a01fa0e07e1c183868e0c8a7a8188e07b31c9887fcd8211f730cb4206900101787ec1ac0fa217a40b4b016a31602217a06a0caa60a8c7a862217a06908280ac02a0a8ca80284988066910904a84a184812a06ea19a882a02a80a8081a82c19a86818880ea02a0281882ac2819a8602213a002ac281bb2007eca819b0e1ba8c2a19b4a301bb2a076d28c05ea32a8eed28c05ea32a8f6ca8c05ea32a8f6ca8c05ea32a8f6ca8c05eab0a8f6a3417aac2a2bb227b419a8cac27b427b0a301bb4a896d096a32a076c28c2c21b2a30329e1db2a1886c2a2acd28c001fb0a58ac282aad2ac801fb2a5b0a3b2a1b0107eca8ec286ca86c8061fb2a9b0a5b00587ec2d6c8161fb4adb40b87ed28032ab4a0661fb061b808701830a8f150d08a0a07f28a0a07afe6f207a7c7f9b9390350d342069001107e638361f9a4980f87e6126821f8b6498107e2f906041f8be41a6178c6479c138c64398e138c649861b8c641a007e31906801f8c649a1f8be419a1d8be439c198b64b986118b64f98138ae51ae079a038ae51a159840ce4398139850b6479811984788e4d980d9851a4f9845980b984980984598419a4598079841a118439a419c4398079a01984398018419801c4198059803984198098419a098649a0d9841980984398039960b9a49801984198087e610600e61066021f9c039a51a087e601e694603e1f9a4981387e70561f9a13e941878a91118a7afe6f207afe6f20320db420690011f87e3066678a1599e8881399e8881399e8881399e9081199e9081199e9081199e9081199e9081199e9081199681881199681881198e838a803663a0e2a00d986838800881a099c858800881be8390808088999088810893928880188919088a0588918a0b8a898a138a60db6c183870c8b8c7ab1d87c7ab1d83ecd03307a730e3420690012e1faa1b87ea22a05e1fa89281587ea20ea03e1faa85a80d87ea226a0261faa8ba80787ea23ea0161fa88188da80587e22881889a80587e32881887a80587e32889885a80587e21a881883a80787e21a889881a80787e2aa9189280987eb20e622a0261fa88798a82ea076a21ea02eaa0a06ea21e628128e92809aa07a8879882c87a809a88a805a887988fa805aa81a801a889988da803aa87a8689a88da803a8827ea10a226a016a27ea12a216a826a26ea106a24a82ea10a25ea116b03ea12a25ea906a046a106a256620a92a046a14a00aa366a06b03ea12a806aa166a16a04eb026b206a26a0261fa88da80b87ea236a0261fa88fa80987ea236a02e1fa88da80b87ea22ea0361fa88ba80d87eaa26a03e1faa87aa0f87eaa1ea0461fa9e058093818a0e95938a7adb77087a72fdf87fcd8211f7fcd8211f440eb4206900128066800e818199880068181998800681a179a800681a119a818800680877a203a021d64a003a022063a06792800680a81c41881c418642001a029081c420694710800680861081c42271081a41880480861081c4a071081a4a012071081c420619081a4200a021c420710818642069080280871081c4a071081a4a002021c420619081c4a069080080a6908186420619081a4188008086908186420619081a4188028984206190818642069280068188186420619281a42003a2619081864a0690801e89a420619281a4200ba2420619081a4a00fa2619081a418804e89a420690885e91a8801fa201808c8189068d8c0a7fa774107f5dda507ecd0330730f342069001576196400f87e1fd8638ef69a6007f61963dda65d8686f0d8658f76906d861da15c075875868ff69161a41d68476996196106d868ff058e6426da0dda61da638ff0dc41d61b701f69b61a760ff0d8e65dc03c161b69065a61d83fc3659901d6c160571905866d87583fc36d99618569b639d61b60f701dd60da6c17197197403dc07639d6583059e6d9708e705d8e6d9058e05d0590d875a65b08e705db05a6d9058e05b03d875b05d08d703910d905b0196456416016c0f69b6c1740631c277416190590d9703d8f0d9078af0dda45901b64365c0f61c4627c2f6116916426d88d86580590a30dd17bd0f9161161964074085c0590a30210591590fbac3b0fd84590590d865885b0016c4945eeb2e310fd86416c085902105a15902102102313bcc3ac42f64161c084485c15a8c08c08c3eeb2eb117a30a1700f6a30250210bb8c38c60eb107d907a10a1618176a302102507e2cd183943105901db07a102101b60276a30210a501d9831431460e50c45681d86580dd881c2f8307460e50cc4681a96847620707d9830e518518d2c41f64483dc13dc940f832e518518d2cc56416448588dc19dc9407830ed1853854c6103a1620a586007f65c3830e53839439852cb9159e0387f65e0c558d38d2cb905960d87f61d0785078558496384e1fdb91d585a1f87f97801f811981888e919b8adb77087f5dda507afe6f2079bca3707f4724887b1cdff87e5edfe07fdf91b07c7ecd03307f761cd07f761cd03b0fb420690010f927004996019066884998094600608519811a212e6016608459a0b996039041820483888a5160c87bb160c87dc33a10721034206900176685e1f87e63836706e1f99e119860f87e6d9566581e1f9be559ae0987e6595e6d81e1f98e599c6107e6796e67841f9be5b9a61f9ce5b9b6179de5b9c6179ce5b9d6007e6596e67846586e679466106698066385e69916610e6946b841f9ae439a439a49be007e6d906691671073866678a71471167107784e678a61947146106f886b82e6788665907146126f8a6b82e688e73946106d8966985675926126f89e6b8366b886590610738a66b81e6b886886590778be6381e1f9c29c6019c1b87e60873816685e1f9829ce0187e1f9829ce0187e1f9831c60187e1f9a29c60187e1f9a31be0387e1f9c219ae0387e1f986239960587e1f9d60f87e1f9b60f3c18a10119c8a7a3acacac87210b4206900187e628e300787e61a80787e6381e1f98e42a0187e69b8107e6ba8087e67a2107e65aa0187e63a8400e1f996a200187e69a0107e6ba0120e2860566db80386185669a0e00e1a60f996a20138659fe800682822069fe4026a1a7fb8098871fea016e18e7fb803a8639fe800ea22a1075a0aa06a80ba87286da00a8902ea1aa00e1ca2061a017b86280a86a0a0081c8066a04a1a804a1aa001fa862003a8c021fb81fd64185890e0f8d4258f1b4d7af8c1d4c7ab1d994e4b30c9d4fcd8211f4f5c5091b4e8b71d1946113420690011a007a022003a021a804818622002067a06ba47240a032001a052009041818284848eb76ff87ba607f87a3d67f87af5bff87311b4206900101106012e0b9221922192292059027923102103141102790210312259009029922990e090399009001209031941120390e259007920b9160f9e418308048c8a7f58181871123420690011d880f87e28361fb020361fb020361fb020361fb0282e1fb2202e1fb220261fb428161f88c20c880b901588c20d080bb020462306830202ec880b88d20c18a09b04302bb281b0832202e433e85b4202ec189db220262304266d0a09b0627ec0809929db22026c18c109db020264189fb2201ec204a66d080990a30426ec0a09b0a1899b4281e4a84266c8c0790a18426ec880790c10a25e434281e4309db043020264184a564b220264329b90c080b90a189bb20b90c28430424ec83e43041893b215b08328bb41bb0a21ed001fb0a31609f2418b0b120f88b1d3c07b1cdff8794b2e707c7d77287922fe307a7512b4206900105640240240564005004056400408400405e488480284e40a01000f610f6018e640063990038de40162102990280401e40a408e402402640240860100900b900920900900f92090e15940da9c18386080a8a7fcd8211f7113342069001041f9007901d9007901b902100390210199029001902101b902900902901b902900902901990310010310199031001031217886400408e404e21029011023916059021021003903102591631007902103990099037920d903192139229921b9260fb5c18307088d8a794b2e707113b4206900121f920387e40a5021f902390007e408e4001f90239061b9023922921790239001031213902390090219060391631001902790e239229003903b902100790399409903790119429941992609a6c18287078d8a794b2e7071143420690010761f87f251200664060461f87f2d21190981187e1fc94194486c32181187e1fc94194486452180f87e1fcb4194c90510980f87e1fc86532192406510180d87e1fcae194992406526480987e1fcb44125064b01b2512100587e1fcb4cb4192010486ca40161f87f2530494ca0432506c8400e1f87f2c06482412026412d06484041f87ec4b4194c120070512386c84001f87f23125320b04801c1418e48650407e1fc8c294c82c1201709921b2101b87f230ad064520270992512101987f2ab41b04c09cb04a8121587f2a94c0643203f24084944840561fc8ad0c45283f243219048404e1fab4308c3204f2408990101387ea3143885320572c0838461f894388530067242e1a403e1fc82508530481bc9028e1848361fc8c508506401dc8840e506100d87f2506530481fc9048e1a0b87f2994890021fa10394184500787f238650a414041f910506c80787f238650a400187f2110992200587ee54a480387e4c0648848040087f2394a02480587e4506232421faaed30480787e4528490a804817c9022a386510480987e450ec08d100674408b86502480987e45081c204815c344325320361fd124084905215c941c344120361fd04230d004013d12d10386a9203e1fd1039054a480fc3448a50e18c481187f440ed2a5209cd44342b4190481187f4414394294494494c00c0a42e50ad3250641204e1fd10d0a494294a801d2651252a412286481587f25125103b49a01c06532d0a4121b205e1fc8ac0e194486414034c0650e4b420e5120661fcb421049438652752e52e48e414481b87f5406494194c14490d2e1aec1206e1fd070c8641541445541441505e1fd2c2b4406c074990d2e510a8e53204e1fd0c2b0314414b92d12412190194c0a20ad21387f4310b142944144b015299153022e501387f42103142903344900172d0e294311201387f422c510334480dd0e294c8ed01587f4c2cd20fd0ea9448e521787f4b144a11d2e432d01b87e1fd0e1f81aa81858f9a1e8faee0007fffe4b07c3b10607f1538e07f1530c07f8c11407e3438e87dec50907ebd91c07ed5a2e87914b4206900118961388e058a60f89e018b60b8ae08be098be00be078c6008600960789e008608a108e07896088608a0896078960086018a008e0b89600a078960b8960d8960b8960d88e0f896098961188e0988e1388e0988e1389605896138960588e17896018961789e10961789e10961789e1096178a600a6138ae00a6138f6138fe0f8a3f83628fe0b8b600be098be00c6078be08be058c608c6038be018ce00ce0389e3f816238fe098c3f83620fe118f61788e109609ce418388130f8a70153420690010f87e1fb07006e1f87ec9b0b2087e6340b87ec1b079a1bb31300387f03303b90bac98158d03d0821fb9018f32e306f40c18118b05b8407f03903863873a61a2c183e2c08448384b81db9038638602e6308310300d8a8c09406121d90a4063813b08320b8d0a26024b81d94605e840c02e2c48044004381d98e10613a103009c08090380190090e0766140900b92039002e831038c006400418e86663a60040040264024b009a0c42c01640063c1798ec00900d916112040c40e300d98e856c38a3819b9010010010090c40e30603663903a0fb8c3a19991140150b06046ec0e036e30f0670188420194c00483eec0e826e30f4019c06210010030308140900fbb03a07b0a3c19c0630840e050a0e10611c0ec0e016e30f4017c263102003a3006ef40e006e30e185f001000c01020120620e4019c0f40e04630f401bc0030040120e18839006f03d03a630f40007ec00ee230380401bb87028c3c0b87ee01000e01007eec0c3c0d87ee010021f87e1f80d70182908c9f0f5c50907ecb80687d6329307b7201887fcd82107bb271007e3949487fa4f9a87715b42069001187ea80e1f880aa007ea84a001f880188a00a06ea00622802819aa0188a00a066a10a044a860280da8028210010210a7826400a90a0ca188a184400642c21001aa210a180a004280a842842a22a02800842a22c22a6408a84290a884296228228408a1062805aa210a8842a210a08408a02228400e210a8a428210a88a1022809a8600a88008600400a84601ea84a04a008026200a0a036a2003aa0a809df418387090d0a1138e87c1a69d07f761cd07a7c5291f874163420690010987e406e4042921790090619902120121990088438464084006504e4084002106212010010090010014018c4884180418040020164388408418a4016418c488488500e48850850850848803884024080922022100080b92090282480202e48021215b9418385078b8bb214507d73f6107116b420690011880d88090058a0920388098010018a09801208a11809000a11811203980d98039341840284858c7fe81010780007807217342069001206e286e305e210281e201e40c0590201e4080080390300e40808c090258240a08e6018de038ce078b6403e2190079841828506098bead7087a58e4c07117b42069001301280b017b01280b01300280308300a813b00280308300a8c00c00a30ea046c00c00a30ea00c20ca8830830a04ec20ca8830830a02c20a32830a05ec20a32830a006c20c20c20a066c20c20c20a006a3282a1ba8ca0a80ea30828c281ba8c20a30a016a308281fa8c20a016438764381e43876810603a0c28c201da0c28c2005b0a08a301db0a08a3005a82302281da82302280588d081d88d0805b0a08a301db0a08a3005a82282281da82282280588a30a201d88a30a2005a8c08c876a3023205a0c28c201da0c28c2005b0a08a301db0a08a3005a82302281da82302280588d081d88d0805b0a08a301db0a08a3005a82282281da82282280588a30a201d88a30a2007b0230007ec08c0268288001fa0a200790e1d90e05906c076610609906301d98c120d98c866632603e6341798ca8602e63061598d28c02e632a340fb0632a30a81e6306a320db0830ea81e630ea3209b0831ea01e6316a3207b0831ea01ec7aac016c18c9a807b26ab001b06326a81ecbaac04632ea826c20c7a8d20cda80db0832e818cbaa0db0832e6326b046c20d9a8613b083160b16a185ec5806c1a861bb0605b060d80f201840898110ecb80687f5c50907b7201887bb271007a7c12192075183420690010ea856882ea9815a062007aa685681a8016a1a405681c8006a98485649c01a8692159221c0a8688485651c0a86884856419a0a86085056418862c6085056418862c29415906218a9829415906218a9829413906298a982942046214298b0a5080f90214218a80a8a508928420a206102106218a02a8a439a912e218a04a0a4798818498862803a84184598812e62a03aa690e620611e62a07aa69421881a51ca82ea98e9196a83ea9c82866a8615a8612860be6c183878c0e0e50e2f07ed8fbd07f21f4c07f6bf5187f7c6d907418b4206900113b80187e8196e18e1a019a8028028030028406b861ba69a060250828b86386386ba73861c087b10a4e19ce9ae9ce4083c043103093863a73a6ba73890888b03281083863a73a6ba62ae24222222ca0420e18f1ae9ae18e1ae20f024ca4e1ae9ae9ae28e1ae4083b08c0c408b86ba6ba6b8a386b8225020c23008c22e1ae9ae9ce9ae088404408308c04308b863863a63a73a6b9021009020c4284093863863a63a73a6b9021021020c088c0c22e1ce18f1ce28e18e310a1020c088c0422e1ce1ae986e98e310a1020f0088b86b869a8e98e310088408c08c0c22e1ae1a6a38628e3100884080b0210a2e1bea18e28e210a10202108448b877a903a070b08b86380665a903a07122618366b9121f1206183e6c48c08308c06704e6448c2c2303109817991206c23031086f124ca30b21bc49328c4c06f124ca101b01bc4840c02840842c06f1210300a10210b01dc28b00a50b01dc2884942c07702401a30b01dc28806940c06701a201a06c06f0a205a4c01004f0010a205a5102ec0103a207a5081081ec0303112009a3081005001002c030310a00da3103081002c0301a00fa10b20400c20c0c4415c2c4060c0042c4219c561fc2e11810d018288160f899970b0799970b03b51f1787b51f1783a7a3c7f761cd07719342069001121b90617926119460990e092e0190e2044d8243806478850041880591629160991e21060d91e2101790e0793c18285858a8901fac07adbfcd07119b42069001016a05ea01ea05ea20024020a84e228880aa0228804eaa002822002a4202036b200a0220a98a20202682a8006a00828818420b028288aa801ea1881aa59062a802e8188287206aa00fa062882a72c13a2a1a92805b2c18285058c0d3535307b4b53507ebebeb87c7ec6f748741a3420690010a411a4120611a060a0611a0222020e11a0220622411a0220622411a022222022411a222022022411a222022022411a222022222211a222022222211a222022222211a022222222211a022222222211a022222222211a222022222211a222022022411a222022022411a222022022411a222022022411a222022022411a222022022215a022022022215a022022a8066a90aa019aa42a1baa42a1baa42a1baa42a1baa42a1baa42a1baa42a19ac42c17ac02c15ac400a19811ac400b1aa036a1900a872a4026a184a1aa19003a8e4006628e404a79003a9642a6401ea390a7900ba8e42864846b10a14078087018286158b0fd680b07fd680b03d6329307fd734b07fd734b0341ab420690012904690481846818222411a0602022411a1622411a0e220611a062a0611a062a0611a0622022411a0622022411a422422211a422422211a422422211a422422211a422422211a222422411a222422411a222422411a222422411a222422411a222422411a222222415a222022415a222042a19a842842a19a842a42819a842a42819a8642819aa42842819aa42842819aa42842819aa42842817aa428617aa400a90a04eb1002a4286046a90a02a9aa036b10a02a1cb026b10a046a9603ac4280198a982a390a00eab90a190a01eab90a90a02ea990b046a79007fbc18286158b0bd200607bd200603f6bf5187caa68787caa6878341b342069001164001f87e4001f87e40500661f901400387e4300b901404041f90c02f01001c04021fb1002f01001c0010007ec400bc0400f010007ec400bc0400f0101bb00b1002f09004004244011c0042c00c11082f091081011083f00103083084409001001c44444420fc4cc04420304024050191111083f0b1111080c006433081091091083f0310191000c016400c01111018470311110b0401e400c0109004213c0042444c200990031091104f07b04200b90c41615c0042c80403e4310185f01b0010803e431018670b0810804ec441bc0c4043013c0031086f0184204c80f0386f0180c810006f03281207f338a4a09b80cc1fcae286036a38a01287f2b8600202733b287f23864a11c8039207f218068372b9286f219a09807aa048e4a0bc803c804c6280d9872182664801ca049e07b873392052846032812012582e806e01300ac864a0c81180c80c804c049601b805c8e0ca01931923baac8109202f20131925b9219923baa4817ca649ee4864c6c8118e28179923929921b929921980198e480f8b2b8a3921933864a648e600664a0fc8e00ab921932864ae19204a1801980fc803b920328060128062814a118a04ef481480980c8e0172006a04ee012007202a052380587f20072817200e02e1fc809c817810e81858a161408029ee078029ee0399b1c58799b1c583b1cdff87b1cdff83dce9ff87dce9ff83901fac0781bb420690011081988018a198a08c198a4086178c40840a178c40840a178c08840a138c404210204e29005881388401e1f98418086050b8c7ec6f748711c3420690011860987e600200688199a81880980186285660021c882608618a159801a2226080a2705e6002182186098818e206668868462001a018206e618809880860a608198a638089a008606629260022002060870a17880122a20188986205e2398e800818218205e3196819c1b8868861a06006186e21868988180186485e23a066790158841c224024688605629060a69080081a318158c6086828008006390158a688602800818e418138c61a20a061062241813884086a412262066080f8c01a91809883906080d99e4188180a46582e218210298680481881a41841a202660861886a012062001889260803886624712019a8908106b8872166016620e60a710290819a810018059888862222061060c89c418800602e8380818801889a8008980fa2e110859817a0e05a40b80af01838890100e5ffe68782ad0007a9259207805a000731cb420690010461f981180987e68468161f9a039a107e704682704604e6181661021c8806846826808196059060841a8182196018681a6059821889a21b6818318099821a91a21a6022690210059c02202001a298612409268468168046180e8008846181e1fa005b7c1828906108fe780b07f21f4c07e8a8c407f4d5628731d3420690011db00b8811b0a81e204ec2a05b215b0a016c856a9803b0a056c1a01b063015a0704d0566206b00aa6056a20a18c02a85e830828c00b05e828620c00b05e22cc0062a15b0220ab0018b04ec20230a30030a18a03ea00a22232030a18a80628880a02aa2c206320a862a818a1882842042a8b26281286620c188a8420b20230a00ea1a0218a20a90828ec00ec2c6a968a8607b0afa2ab00bb0ada0a300fb0abb017b0a3b00be14183068c0c0fbeff307fce9f407f5b85a07f1485987f75f6707f1485a0751db420690010e6101390602e498404e418481641c404e41c400e41a405e41c400641a406641a40441c406641a40441c406641c40241c406641c4004186406641864986406641864986406641864986406641864986406641864986406641864986405e418e4986405e418640241864026100984026100906190090619001a40069001a400218e40241ae41c41c41821c400641fe21a400641c7f90019069fe40164187f9007907d900b9079900f90759013907190179269921d9260de4c184878e8e0a794141407faee000721e3420690010b8840661f884181787e210684e1f8a4981387e21460461f9021470361f88419841860787e2106610e600e1f884198479c087e43984f986178841985b9813906617e603e21066105f980b8a51a438164f98078841984382e4d98038a518438464998038841984384e479803885184385e47806294610e1791e604c14690619906e184c14610e19950387002c1461061b930b87000c385184186e442e580c384984386f0b9f030f40e3a819c0e9c0c3870386a05f03af030e1c0ea2a04f0baf0b0e1c0e20aa00380bc4ebc0e40c387020a1ba09c2efc0e40c387020a1ba07c2efc0ec0c38703882ce8170bc7039002c3d03a8a8e80f0bc703b002c38703d03a01c0f3c2ec0130f40f40e830bd703d004c3d03d03aa42f5c2f4001b0ec2e3c0f7c2f4203b0ec2e3c0f3c2e1c005b0f40e5c4e9c2e3c009b0ec2e9c26e5c20bb0ec2ec2f9c20fb0e1c0ec2f3c213c06e1c06edc019c2e7c16f40007f0bb7100e1fc361380bc01860916928f8db9407f8c11407e6361187fcd8211f7c9494907f8db9403f8c11403e636118371eb420690010387e30061f880086107e3102841f8c400e1f8c400e1f896107e2103041f8840a40061f885021f880102108188001f8a92c198a51882c82819902106216a83e47a0ea20a84e41a06226a0062391681a85a8880631221926a36038a48c51a8f80e2022824988288d85e828687981da8688482880261fa801c04184070b0e0effb6487de71cb07d1e04387f8f05507f8f4660741f34206900148361f9160787e458161f943100587e4096400e1f9027900187e409650662016409648a118a0790259228362900b922d80e21900f923b901390e2b902901d942194290087e4388640161f9021900587e40860787e40c40161f923100587e40c401e1f903100587e40c401e1f922900787e418261f940987e418261f9405bd4188840d0f8a7faee000711fb42069001011ac1dac0987ea24a066aa2a80e1fa88a86aa15a862a8ac007ea22a18ea00ea806b1c4206a86ea22a1061a88280aa8a80a8828714a206a05ea2451aa20a20aa0eaa2a0861066a892a13a88a843a88a88da88a851c42a92811a2a1c4a881aa89a892841865289280da8898e421eaa06aa0ea1c4198a22a036a20a1061a887a8028602885a861067288a809a889472887a807a883aa518ea22a01ea224198a21ea026a216a9063928a807a882841aa87a80ba887a86194a20a01ea20712a21ea03ea21ea9851a82805a882861a889a811a887aa49aa22a00ea2049aa226a056a226b1842882803a8814a226a066a22ea9282801a882852889a81baa8b90a22a04a2071089a8007eaa26a22a02a227226a041faa8ba81288286a887a80587eaa1ea04a204aa85a80987eaa16a02a20a10aa16a03e1fa883a80a8818aa16a04e1faa9280a882887a81987ea22a02a216b0761fa88280288a8e107e1fa812a0f87e1f80c6018b8e0e1a0a7fa786607dec50907c3b10607f1530c07420342069001066866618266384e6581667846678066b83661926806712618367126184680612703e610210600684602614604e2126026016612218138a6036612205e2180f982101790603e6081990603e610199260366101992602e6121b90602e6121b92601e6141b92601e6141b946016c2c19b0aa0c016c2cc056c2c83007b0ab211b2aa0c026c2cc836caa8b009b0a3b00bb0aa4c02ec29607ac8288300db0b7a0a22c03ec2e683013b0b5a217b0b1a2c056c22ada4c04ec206abb0a22c0468a88b2a3b202c8300db082c830030e130b20c02ec2868300bb0a1a0c01ec28e8300bb0a1a0c01ec2868300db0a1a0c016c28e8300db0a3b005b0a3a0c036c28e83001b0a5b011a8e83001b0a5b011b0a1a0c006c28ec04ec28ec04c296c056c2868300b0a3b017b0a1a0c02c28ec066c2c8300b0a3b01bb0b20ca8ec076c2c832a1b0007ec2a832ab2107ec2ac00c8161fb2000b6818b08178f8a7f5b64907e58b2607a2f5b64902e58b2602520b420690011e406e405640664856485649a0f9c483e459a079a4781e4d9803985d8c4598118418864f88e419a0184188e4f896419801850964f89e518018489e4198641896419a489e418066142390e694239066006610631166906310e600e613e602613e6016612e604613660266126600661266036610e6816610e68466382e6380e1fbec18608891089e1e1e07b4b53507f6bf518722134206900101e406e4046486648465056418364383e4781e4b81e50a50a0397e211e2044b884b884b880936211e213e014621265f97e5f8064b97e0194e09460394e09460594609221260793e019221021060b92e0790e1390e03a7c1858808900a79e1e1e07121b4206900101792159413906139061190620464184e4184641880f906203e41880f90e202e458809936113e09011360791e1194119541830608888d496ab07e9afc3071223420690017e8101da04866420485e4225056892683e839260840293906184810692e60861005984b98218402e459841a19900f99c18286858a88f038787a88c22079c081707c012b487322b4206900105e4856408404e488404e408484648848464084846488484621060f902140f90e0f9160b91e09936113e090110291e07942141194119bc1838588888a9259207ba349a0712334206900109e638a66590610610658a602619461826080388610e6080d8841a41a4080f89e0591c01c0c020004040500020503098a7b23728878f141e07223b42069001066187e6581e714705e690310704694614799029429c098518e50b6419c439c014679071926794712679071946b907126f903106946f9071267886191e6190679271021962107990639021060068a70841c09ae09060a618a41809849a49849801b6402612259011a49c41a09be11a40c41a019a609c640066382663846d9061060061f9841b64980187e60a699460061f9829821841865180187e6906926922184180387e6146942920787e68850c482e1f9c2190683e1f99619e7c1890a0b130a5b49787ac429107c7cba507224342069001011de11b621fe29b629809070c618221a40860241862986090218408602408708638241a039221a218e0f8c6006184e484418079d418385848a8a7b51f1787a1138e87224b4206900101f9a107e7001f9961b98e41a0d9c498e51c099821461942186059821263946381669461946581669270a49a6039851a2946b80e618a49de11a214739070467806b9261846180e618061269068767106821f9c0ac418488080c8a7ecd83307e9d0af87225342069001ee3f8fe01a0679067a0018803a0679067a00da0659465a00da061906146107220d8a711e6a40f888184b9888462a0610614610624138a690e624178a7106a41b8a87801f88e0fa5c18507068d8c3ae9307e9d0af87e3949487a5159087325b42069001513ac01a90ad05ad0aa0c4a44aa06a41e0466c41e044ec28042842040ec40e40ea8302108105b822101a9003020140ee11018e4484007c16e188406a4009c06c40e41e09c4e03a7c18406058b0a7a5159087978d8b8799970b07a9259207c1a69d07d0ba9987b51f178772634206900101640a60790295e08c5b80212e210e294210108418843803102101084188438421003885084583e5084384e4880140799c18385848a8c7ec6f7487126b420690011a67f9fe497e28067392099ce408099ce408099ce408099ce408099d620267590018fc18406050b8cb4b4b079b1b1b07a2a2a28722734206900104b97e5f883f920195e0994e2100994e2100994e2100994e2100994e2100994e2100190418386050b8a7a6262607127b42069001016614612703681ae81062041805a06a06906206204a0622400681060081849829270081a8028101204982108106220a06a24806898498418800681889201a0620498218800e60081005a0e6201ba1609b0c18406048b8d0ba9987c3ae9307e9d0af87fcd82107328342069001126586e49be13907b81e21845982398098a6390608e602e218e41821980d8a639060c1199e41c159843980395c18284848b8e3949487eba12107c7228b4206900101a02841f8a880690a107e3220a4280e1f8a878a0387e2a1e280e1f8a890818a0387e2a242242028061f8c89089088a107e2a440089088a007e2a440295a7e01a366909128f82e8d92623613a09f85e827e19a2625e1da2624e007e8984236107e910898161fa2e13b741830909918a7c7ab1d87b6209687f761cd073293420690017e61841f996007e7106186e61906584e61946927036659470049a059ae498640249811ae41983184046806591668866920198e519621926900198649962194710019c498623946390019c418e3146592019a49811a4199e4180398418039be481e418059b6418199b61d9a607b8418508090d8a7a8188b07e9d0af87229b42069001061f87e2187e258662d84e31821a22836219a3224a0202e29260c89280c078a488e5223016294219488a808058a48c69288a90803a050a69480a838803a0669288a898c0a889488a8d902a00a8818ab22648860a888801a968922902201da0290218807e8989001faa620a021faa0bec18588098c8bfbfdc079f9fba07e9696907c7a742a3420690010461fc80f87e44c0787e42125841fc8423201291287e44884084a0ca24a1bca83084a01ca2486403f342c4a05c821ca481e44a40903121009c848894ae888d100bc864a423a4432e480fcae4c421e6bd284723872992b9684a13c8e3cae19a831231204f238721ae1b0188b1231204f2b8a4c6486a5033284f23aa3929c0d4817c8ea923c1242cca17caf48f049031286f2b923c12587f2f841fc9e15d8c185088a900b6988a07f2ccbb079b100c87f8de5187c1a69d07fa4f9a87cdb31207d4258f07f8c1140782ab420690012e2386e218e2066218218218205648863884181e418223806500648261f87e1f87e1f87e1f87e1f87ea016a856b04aa213a2a80aa06a03681ac81aa0baa81ac8aa0faa8aa028613a86024c182860a0b8d92f3d07f75f6707f75f670bd353530be234430b42b342069001990e1d9160f94239de50964826409e7b8b6401640a67b8be03902b9ee2f901102b9f631900902b9f633922d9fe31922d9fe31922d9fe31922d9fe2f900102d9fe2f900102d9f631900902d9ee2f901102d9e6319001902b9e6319001902d9d6319005902d9ce319005902f9be319009902f9a635900990338fe403640c63f900d902f8fe404640ae3f901590298fe405e40963f9019a8238fe4076a0c3fa8007ea083fa8107ea0f6a00e1fa839a80787ea256a02e1fa891a80f87ea236a04e1faa85aa1987eaa2a801f87ea821fe241898b92958a7faea5207dd57ce03a2faea520242bb4206900101181b98059a179a059841813984180598498119841805985180d9849805985086d88498059850841884388498059850841884388498059850841884388498059849884998059c49c518649c019a41a41841a41a498641a11851a51a459851a098497e6006145f9a517e6006145f9801a49851851c51851a0986418641a01a41c41a059c09c11a09a01cf4186068a0c8a7c7a2a1210722c342069001041f9080481000f642072048ee4a26a240ee4246a240d6d1089c8902db0ea9089801a8102b2ea5a2682622d2de81811a82fec00ec2d6c580ec296cbaac026c9acca86c02eca86c286cacc036c286ca86c2cc036ca86c286c2ac846caacacc28c856d2ac2ac28c076c9821fb2ab21fb2a1b01fb0a1b2007eca8c841fb407c5c186070b8d0bf060607fa038387f5e29807efea5307cabd0907a352cb4206900128381e1fa025a40187e808838c8821fa2e320615a46288b8868581e21806a8e8a897886b02710639495ac0798819881168baa0ba441b0834832518a05e810c1be8aa1bb081ac20630830622a876d1ac1a818928007ed1a8188188aa087ed18c18c20b00e1fb1617b8c1830887908c2b29e07f761cd07e9d0af87d5c1a787c3ae9307fadd368752d342069001018ee0db05305305305300f99e419ed01ed1964196aa2c00ec28663b063a868b0130a59864186c28e8b0030a1a0a20a1c41c032a3a2cac93213003b0a3a2caa93013b0b22caa8b017b0aa0c00c2c83017b0aa0c00c2a83215b0aa0c02c288b017b0a20c006c2883015b0a20c016ca0c04ec20c026c20c046c28c036c28c03ec846c801fcb418787890d8c0288987fbefdd07faf46a87f2d3a687e4408f07ecd0330752db4206900156286630562384e2380650c603942d808016418840c028803641a881a17a8620a048280fa801882a11a8605e8a80998c1840606098ed58f507f467f887d9c86007ab173287bb21450742e34206900187e418407e41801415942180885026438a61008c518c4806408e41862190601906142791e0190610e213e039061062926601e418418847980b98418845980f906294684e418849809a6418386068b8fdeeb287fd680b07dd4c088722eb420690010187e807e88468181da06a00da06a019a06086200b986806680a4180b98212806680a420602660a42019a0212818801e80a4a017a021081a801e828290805e81081c801e82880842015a04a072007a062029080468128186801e81a80a4200fa461a00ba06a05200ba8818e80368286a1e03a061a8884682867a88048286a8885e82867a80a0a2061da4e1187ea221587ea5241870989118a8188e07a7c7ab1d87f761cd07ecd0330742f3420690010f940f92310079425901102d90010310299011031221920390219060990279405922990079225900b92310119411841850786080a5050507f28a0a0712fb42069001d396ed1a8d195ed20c3a8c80c28cbb7e830ea32130a34dfa0ec3a8c80ec2ac788c08dfa8c826c28c388edba8c836c28c38cdba8c846c2ac88c08c08ca86cba8c856ca8c08eca8caac7a8c86ec28c3aac1a8c7a8c076c2ac1a8d20ca8c3a8c87ec2cc2ad22ca8d2ac001fb4b306930a3b2107ec9a4c782e1fb1e19c241850a07948a7ecd033079514a78788850007a6a6a683ef6e698753034206900106a0eea816b0eeb006b0feb04a22a0eeaa0a80aa262880d6aa060286a26242ba26a0662881c898929e81c819aa98691b6859a82a818e8aae918e82c6793665a0a80a206390612661063a0a02aa0619069269269063aa12889c498418641849cb00ea2271269269261aa07a889c49986a82ea2271a0a83ea226da2a04ea2467a2a066a247241fac818061fac13cec186078a8e0b5068687d08a0a07f28a0a07c7d08a0a03430b4206900106c0eec816d0eed006c18ee634600d2a3b9aab0630a58d6a5b28aa82c2baa82868b292a82be92868b281a868ba96932a20ea1a0aba0ea32a23641a2ea80ca88990819089a8c02ca88590e81285a8c006ca88390e81283b2600eca88190e81281b2601eca88190681081b2602eca88190681a8c83eca88da8c84ecaa85a863219b0b22ab21fb0b340fc8c185878a0e0991e1c87a5b49787b55f180791101a07c7a5b497835313420690010987e203e1f8a0b87e2a80b87ec08a8261fb022a0787ec8aa0161fb4e341fb16e32a30e30078a05b8c1b8d2ae2ce3009aa29b442ae22e28c38c826b303384b8838810e20e20e28c38c03ea1baa3889065a0a38c85eea8898c39a828e3019ba42073066a0e3219bca22a18d18828e321bbaaa263262ce301fbaaa0c1aa30a38c801fbaa1aa3b8c041fbcaa0b300587ef286c0261fbcab00d87ef584186098b100b4b53507a9a42607d3535307ec6f7487a7c7a1aa2f07631b42069001587e1f87e1f87e1f87e1fac701661a01daa63a8604818418e805ea1c42841a80068184986804ea1c4886a005a860a41c803ea1c48a681e81a2906a8802ea1c48a6a809a868849aa2009a861429a803668a49aa816a1850c6200fa068a41ca2001a862848c62813a068849ca006a1848c685e7084286aa0a862848a6866a1a2127280a86084086a81d9c210a1aa00a1a4086a0007e68a41c8286126a8087e70841c82861021a0187e6884286a0a0a6200587e608498a00a18a81e1f9c418a0062a0b87e61a00a80d87e61a01587e62a0fa4189898c128aa2ca907a7d3535307c7f97afc874323420690012e1f8c1d87e25921587e2994c01e1f8c641b06107e2d916c7821f8ae43b2ea801f93ecfac087ec37ea1841fb5ea3b2a041fb3ea7b06b07ebbb26b06eb7b4eb05ec1aaec980ec39c0fb2df826a246300bb4df826a3283209b4ab460b4a81ea3060bb2ab3ea00ecaa05a860bb2a84cba805b2b06ec2805b4a00d2807b0619b0a01ed280b2a02ed056c2a07b2a04ca80db060ba8d2809b401b2a026a30818c81ea34602ec816ca807a8ca063005a8d20600eab2a01ed01ea3483005a8c2405a8c9ac00eab063007aac826c98c00ea34818c006ab2818c07ec816a328b003a8d206300d87e8b203aaca0c801f87eab41dfcc18a8d0e968f1530c07dec50907f8ef3e87faee0007c3b10607ba299083532b4206900106c16ec816d16ed006c196ec184c2ac95ed28c80caa830a156ca860308aa82c4baa8a8683292a82cc7a892868b281ac8da968a8ca883aacbac83a8d21e6da16a32030a20e68c68c6a0ea300b2a20660a608660a620ec84c2a91821c29c21893403b0aa46da06ca805b0aa469a06d026c2a91a8c83ec2a8daac04ec2c87aac066c2c92c1fb4a18061fb413ccc186078a8e0e3cb0007e6d48987fbe6a307c7e3cb00039f9fe0075333420690011f9405906138c480648860f88e4824084896400e48c48a40040a50c48164188e4886408482e409e488e404e49886405e40c4004188405e40a40240a505640c40240c405e41806408485640a4016488404e408402640840464084036408403e48464801fb6c18687080d8a7fffe4b07133b42069001561f94e2b8443816438164381643816438164381643816438164381641880590620164188059062016418805906201641880590620164188118c18b030b858a7a0a0a087134342069001b87e50761f916e8561f926f480787e51b87328107e53bd25a8087e4bb8f2ba90001fbbf2fc4087eadcb70230041fcdf1232c0107f2fc069487022007f149f01a8c129c0906691ae8c133c084017c909885ab2b80f23b5203723a873182700cc480bcd3f82704a24a09cd0cc60cc881f04860bcb0212fc003cb02007c40bcb02014ae80172c0886f240800f34004c801f2186724080172a10032c08027305722207ca8052c0802f2184724009ca80072a009c120ac4807c13300bc880172a007c0a482c805c0ac823005c12c007cc07c0a4a24805c120d200f029233200f0c8c4a05c328272b1200f029288c4803c1288c481fca05c128b2017229208c480b87f20b201f04a24a0d87f282f04c1d8092018a8d0e968bb214507b5451807c3b10607faee0007d7316607ccf2a807b55f1807ba299083dec50907834b420690010190a31e481e210a32e4a00188d9a0008dda0228d380628c98a300a8cb82628c18c82ab26098c80eab2a30e0faac2043413aa620a30079f418385850a0a793131307a8282807c8c8c88796969687b4b5350753534206900102706e70460c605e60c600608e1788e688e1788641a210305e219068840c1788641a210305e2190218210305e219009a2981798290019c884e89a09a213a20da40fa211a40ba413a0603a0617a3e1ba2e0baac18187080d8a7bb214507ef67f487d73f6107335b42069001061f87e4187e458664d84e52841b2483641aa5326b0403641aa14c9ac140792690e732501649c419cc92c10059269429ac92d1003b071229cc12c39003b0629ac92c9940b8c9cc92cd984b00b8c192f32669060b8c9001b96c9a4984301db0498828c07eca8d001fbaa30e021fba0bec18508098c8d2b8dd87bb214507fd680b07a1138e87fce7a107a193a887dfc982076363420690010987e1f87e1f87e406e4046486648465056418364383e4781e4b81e50a50a0397e211e2044b884b884b880936211e213e014621265f97e5f8064b97e0194e09460394e09460594609221260793e019221021060b92e0790e1390e03aa4186080a100a79e1e1e07136b4206900109c1b9c118306e3180182385e239a2385e219068840c1788641a210305e219068840c1788641a210305e219009a305e310019c805e81a09a213a20fa20fa211a40ba413a0603a0617a3e1ba2e0ba8418187080d8a7f1a7ba07fb626807f747e007337342069001573bc01b96bd65bd6ba0e16b973a81b965e006166371e16616e360185c783806162185806161a164960973a0d886206163c843161b980382016161c8658a49721801f858f228c586e6009e174164965161e009e4e03b2c18386058b0f374fa07c7e63737b707d9696e87ca4c4c07e668f487d05d7087be596287d6da6d87af456607cce36707cc27a6a687b37b42069001dbb7eb5afecda0a798a7a0cd826829661062968026c826828e614628e8026c02e828661021021062868076c28661221262c887ec2c61031062c8001fb0b18488498aa2087ec2c61061062a88061fb0b18a18aa20587ec29ec0261fb1e15b341848906918a7829f3687ab2b2b07c4c4c487d0505007e86868075383420690010573bc01b96bd65bd6ba0dce5cea06e59e05e6059e05ce03805a85a058e05925825ce8362168165c843161b9603620158f21962925c85807d97228c586e5809d87059259458e09dce03a9c18386058b0a7d1cac987e3352407c4342f87bfb71487efda9e87fae34b07e7612707fdf7bf87f2c9bc07d856d687a38b420690010398e1d98e099ae159ae039ce0b9c29c31811ae4087588659029809b641ce21a640860071886f886b90778871fe408738871fe4086886d9021a7f9021c21ae41c7f9021801a219e41c099be41a09ae41c0d9ae41a0199e41c1199e41a059ae159a60b98e1b98e05b541848987930a7b4b535079e1e1e072393420690010d87e614612703681ae81062041805a06a06906206204a0622400681060081849829270081a8028101204982108106220a06a24806898498418800681889201a0620498218800e60081005a0e6201ba1609b1418386850b8f96b3487f2dc2707fe795d87fffb4387339b420690010987e1f9a61d906f84e41ee07886906609e601e298e41823980b88639068c6036298e41a21811886590685e65900397418284058b893131307a6262607c723a3420690010162126078849a8998e0949b80422e420e4a44201108190819801480880442064206604420039091083980fa44206604e890024079cc18305848a8d73f6107b6274407ec6f7487c733ab420690010387e50161f903100187e408e4041f9023901b9201903101b902900194199221900a2620159225900a06a01192259260089c802e489649868186801e489e418e818e801640a6418e8196800648a6418e819e80248a64996819e80040ae419e819e80240a641a6819e802409e41ee019023907ba003922907ba0099281e6804681ce886681a68021fa160fc841850b0b8e8cf0b8b87ff800007a7c733b342069001047cffc1df4fb7a17f57a3fa11f5ff687e02fb9f97b7807e976bede5ede00fa1dd7a1fdb7801ed61c4e7c076e97e05a1d913ac1265bb0dda3f806d642eb24986e1b2e010d87af806b640f14a5986f0301d9a81b59032e1b2a10212f4be037ad9038662882a4b2e48fa780be96400b8720a20a38c3929e9e027a40139f33e9e01f000f27d3f2e9e04721d0767d17a780fcb41dc741e9e02f35379d5a7809cd4def57809cb4d97fd3e01f2d175ff47807e961dffa7809e961dffa7807eb75ffa7809e975ffa780be96dffa780de985ef8e9e047a6373e3af815eb93e9e877b1f813f8c18a0a0f910803080078030800380450007b76f3707805b800780518007804280078b7a1b87ffac8007ffa30007ffcb1707ffd62f07fd428007ffc22b87f8c11407e3bb420690011188611884c0e280d884a2c280b884c0e20a02e2128b0a0362110388280d88440830a0362110388280d88422c280d88440e20a036211030e280f884388280f91020c280fc2c20a04643082811c0c9013c040815b141878108888d7af8c07efea5307f764db87a2a12107fb726287bbb93907b71b8787a18f080773c34206900102e1f88c8261f88c8261fa8e320787eab2e0161faacb801b861baacb813b609a96e30e006ebfeabc801eebfe8120bbcc5b9e6a44826c9a472065a20fa1e63a065b80fa44a065a0ef04681289c81a81b861392818681a8b8e159089c89ae785e89bca186e81b8eabc1dba6a3c1fb8c38ea3c087ecb86a3a107ee30e78061fb8d3a107e1fc3c187080c0f8faee0007faf5d207e7db0007a41a0387805b8007ff800007d349000763cb420690011d921b9417906159161391611916210095e2101156210039560993617900f8e418306058a0a7b9b9b98713d342069001ca0c4b6b7b1a09dd06a372c5d81cda0c8539490d85c0f613645baf56a19e5fd200000000000000000000000000000000000000000000000000000000000000000000000000000000000d34602080601880380380913d3903803d829020815114023df300050e00d600e400f200ffff0018054e06de08d50b310cfc28e20803e01f807e0a388200f807e01f828e20806e0a38821d081e01582a2007020180662002c1c0801c38841d08001586020070203802e20f872e20074200056180801c080e009883e1d58800158601c880e00588561cd8601c0601c00561c0801c080e0108661cf862208700118601c0801c080e0008761cf8a0188801c00461c0821c080621f873e28070188801c003e1c060207887e1d38622007000f87018081e21f873e28070180801800461c081e21f8746280701808018003e1c060205887e1d18a01c0821800461c081e21f874e2086200f870180840e08221f874e20862011860205887e1d1882180801800461c081e21f873628082180801800461c080621f86021072e280800006020060011860201887e188801c0801c78a0200021808018803e1888421f8642007020070e28070200042006200d870188801808021f8606203874200006180801800361c060e21d86161c0801c8840038602006000d87019008060602178241606061c3801e180801c00361908002018081883e160206190801c18a0200016200601c002e18188006021620b822160206168781c18a01c0800038801807000b8602085a083858088826090580818581e0706040a01c080010602006200b860208581e024168242098206160221f0801c18a004080010602006000b8601a0401e0581e8201682062098206160201e0581e1870628080010602006000b8601a0401e0580c0580c078081860207888060241e58581e07062808001060200600098602006a1e0580c8581e0300807a180801878882087a1607860c0781c18a02000418080180026180481a8400c18580c05819080245888200882005a1e18581e87062808001080188026180481a8401e0580c385822092207888240881687c160301e870628070010801880261886c1e030160321606022090e21090618088168781607c1c18a0208042006000d8601a1832168802209219090e19090220981e38706280702000418080180036180801c18782009820098240642478642408821071e2000061808018003e180481d078260702009219091e19090220801c988000860008602006000f862200721e072200982409825388820071e2000419080188046188801c1880268916260916220821c588018000e190056180821c0801c08222892230802289c2209820071e180021858066210702007026080223880e220841c0801c0801d080003862000620198841c080e180801c388161c080e2200061800018000180001800462808a200882087020864200716190502107020898180880086000860000600138a02618821c08012050188801807162086014860210922688800786000f88826189221052180821c0801c188424052180a02009062688801b888261894200a020052240821c0801c18801c08224050180a0208906260a02200662209c2418802806014890180722007062007218080140601c0a020090e280880178a0270942006028880140621d0801c38801c8641c882241898280880158a026894000841c08018072180702007228070620072200722106000092260a022005e2809a248042107262807228071e20000e2409a22005e2809a2480162107062807062807220180162409a2200662209824802e208702807162808200b8902688801b8a02609200d883600b8922608801d88a2609222801601f8902688800007e2808c28001601f890260a200f81c381928f1b9b8d4413881e2d8ac81f1ecd801c5379801aa991481aa99148dc7ab1d81c7ab1d8da1adfafafa81b51f1781b51f178db31c9881b31c988dc23f4381c23f438dc1219201c7b4ab819c0817011381442069001043101987e2a260561fa02246101587e839848561fa061a040561f9a81901587e85981587e839a1787e89c405e1fa0720405e1f9a910805e1fa0e605e1fa0e6201587e91a485e1f9c8901787e8390805e1fa066101787e8198405e1f9868121787e83901787e83981787e819a405e1f9868901787e83901787e83981987e91a405e1f9868101987e8190805e1fa0e60661fa46901787e81a89019b01da0e4056d076819815b0a301f986404ec28c001f9889011b0ab01301ba4604c816c2ac04c86689a13403b0ab00b41b9a8100b0a32130b02ca8c076902c2ac82c2c0b0ab01f9a800c2ac80c2cc00ca8c87e6204b2ab0030b02c2ac021fa2610c2ad28c280b0ab0107e6a0ca8ca86caac00e1fa2ca86c28caac066c982834ab0a3b219b4a1b1ea30a3b21db4adb2b34a30a076c5a9ec28c5821fb0ea1b4a30a380e1fb0a1b06a306a0061fb0ea32032a34007ec7acd00c2ad021fb0a32a1b40b0ab00187ec28ec1806b00e1fb0ab41d80c18190899b940b55f1801a5411101cdad1e01ae1a9201dbc11e01d7af8c01501c420690017b37db419b57db163019b37fb0615b56dfec856d59e09d96c58c04ecd960fd8ed046d58e13d8ed03ecd9615d8ed036c59617d96c82ed58619d96d026d58619d9ec826cd8e1bd96c826cd861dd96c58c01ecd861dd96d01ecd861fdcc381ecd861f896b0e07b36187ec5ac381ecd861fb3630e07b5707ec981ed58c581d99631f6016c3d8199801ae30f6817634705e638898e3076817c346221998e206dac5dc85cb2624e1811984206388188537740f1652622e180d98098e226a35636720f1522e188ba6016638098e22623565c81ce14a2622e1a401ee0089a81d078f20718d491a538c00e63887d2a538f546341a06a043ac99c83d8ad38f581ab4a4e33685dcc558f581d0a3163b07c1b367b5563c1e5632fd33d30763561e3e72071b58c9f3049031031d3167b1a7dc03c59b5be3f32412792412f9c796bfbc85c6d7787c4b7c59fe1f201f3e3d9f7124123c127365f8fc017cfafcc9049049d49edbe5f207f1eff1fe1dbe5f00bfcfc1fd6fa60ffafcbfbe0df1ebf2febf20bf3e1f1afdc7f87a73f7409f3e1f5a7dc3f87a75f7409f5f707e1f5e1f0fef060bf3e1f0fe7f17f7060bf07f75ebf0ff7411f3e1fffc867e7fe0d80ed01908b18140a0130e01a1b51f1781b51f178da5159081a515908da80a1401c1cd978d8b81978d8b8dc121920d9c08170dc7ab1d8dc1a69d01e0244206900142eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e2a2ab2ec06eb2aa2686e1f8a8aacbb01bacaa89a1b87e2a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2ec06eb2aa2686e1f928aacbb01bacaa89a1b87e4a2ab2e416e32aa2686e1f9a8aacb91010b8d2a81a1b87e6a2ab2e420c2eb2aa068661f9c82acbb083138caa81c1787e6a2ab2ec20c4eb2a22685e1f9a8aacb91050baca889c1587e6a2a34e4201c4eb0aa2684e1f9a8aacbb080713ac2a89c0f87e720ab2ec401c4eb2aa2683e1f9a8aacbb0817138caa89a0d87e720b32e4407c2eb0b20702e1f9a8aacbb101f0bacaa89c0787e720ab4ec209c4eb2aa2700e1f9c8aacbb102f13acaa8986087e722b32ec20dc4eb4aa26187661a4ab4e440fc4eb2b246185661a4b34ec213c4eb2b246382e65a4b34ec215c4f32b20679a4a1b4ec417c4eb4a1a066fa06a1b06ec41bc4eb4a1a66a3b4e1c41dc2f306a3a3ea3b06f406007f0b86c1adec7b871041fc4e3b06afb0ee1c0e0387f05b86d3b9f0381e1fc1ef336e1c1e1187f07bcf0786e1fc51f821f87f1b841f8139818f8f991e0ec828281fbc58581fdf91b01b55f180197b86301c012b481b990af01b810b901702c420690010462f87e21aa621856340210ab9021836c8903c42ae43908a0bb0238e42ae442ec00bb1038e42ae440f400bb0e3c0429e428441609b06bb090a5a24bd1026c9ce90a392812e42ec00998c1901c42968108110bd0026630e390a790a11038e0998c38e4aa64397001e63073c42a6442f420798c3a6bb029e4bb01b80798c3909d012b14f406e01ec38709903843bd0bd081ec3a6c0ec06e3c2e5c005b101ae7c4e42e9c005b06bb701ba70016c18e9c4f44e1c405b06b970b9f05b90016c18eec2ebc06ec00798e4261ba713b0b9001ec3c7406e3c0e3c209b0e1ce3c4e116f4009b06baf01082c810f4009b063a7110a392e4209b2e5c4e12a591102ecc0e9b0386422b2103b0036cc06c0e390701103b003e432ec4e3c4e42e400d946b870bb0b8710364286e59ae7c00f90a02c19f13870046a82d18e5c2ec011a2a006d397039005ea016c42e1c20387f47ca087f54b54944a1dd323d32d3306744874487449438774c8f44a087f4cb4494480512001fd13014480480512801fc814a0500d32041fd120328340061fd12034481187f283e1fc80980e181921018900a5b49781b55f1801c7ab1d81ecd03301a2941e01e5edfe01991e1c81b31c9881c23f4381a8188e0190344206900144e384cc43e945740a84572a5868196556c41a3c346f10ae9b277ee31db737fb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd6602080601880380380913d3903803d829020815114023df3000d13b227633b144ec56276762789d99d8ab13bc4ecd89dec4effff0038011c021f03100407050d064e0745087909670a6f0b9e0c8c0d9e5e885e1fa41787e885e1fa41787e905e1fa41787e905e1fa21987e885e1fa41787e885e1fa41787e905e1fa41587e905e1fa41787e90561fa02201387e80a883e1fa021a20987e888e880e1fa429a21fa0631a019a4418c6884e891e33a20da24d8ce802e814e31a205a2694633a001a26394631a20a06794e2da20a06b9462da00a06f9462ba00a06f94629a01207194625a003a07193e23a007a07193e22409a07190e8784681c64a2007e81be88061fa06ba00787e819e80361fa061a01187e81a804e1fa06a01587e880e1fe2c1921096920a1ffbd8001c1803d800130154206900117a0205e1fa2205e1fa21787e8881787e8881787e8881787e8881787e8881787e88661fa0205e1fa2205e1fa2205e1fa220561fa41787e8881787e8881587e818804e1fa06a0203e1fa061a020261fa263a20387e91a68081fa0671a0205e910671a0204e891e73a02036893673a00ba0539c680805a2690e690e73a0204898e439a49849c68080a06791663926da20a06b9469906da00a06f90679066ba00a06f92679469a01207192610710e65a003a07194610610e63a007a07193e62409a07190e8784681c64a2007e81be88061fa06ba00787e819e80361fa061a01187e81a804e1fa06a01587e880e1ff741921096120a1ec828281c19e1e1e01301d4206900117a0205e1fa2205e1fa21787e8881787e8881787e8881787e8881787e88661fa0205e1fa2205e1fa21787e8881787e8881787e8881587e905e1fa2205e1fa220561fa06201387e81a8080f87e81868080987e898e880e1fa469a0207e91ce806691e680813a261fe8080da26590673a00ba06591e71a0201689964b9c68081226793e6fa020281ae4f9b688281b64f9b680281c64d9b680281c64b9b680481ce479b6800e81d651be801e818e7fa409a07ba1e11a075a2007e81be88061fa06ba00787e819e80361fa061a01187e81a804e1fa06a01587e880e1fec41921096920a1c1ec8282819e1e1e0130254206900105ea081787ea881787ea85e1faa205e1faa205e1faa205e1faa205e1faa1987ea081787ea881787ea85e1faa205e1faa205e1faa20561fac1787ea881787ea881587ea10a04e1fa84a8203e1fa841a820261faa43aa0387eb126a081fa8651a819ac61946a0813aa6794ea080daa6d94ea02ea1ce51a82016aa27194ea0812a839ce51880a8879ce4daa0a88b9c64da80a88f9c64ba80a88f9c649a8128919c645a803a8919be43a807a8919be42c09a89198ea7846a2466aa007ea23ea8061fa88ba80787ea21ea0361fa881a81187ea22a04e1fa88a81587ea80e1fecc1921096920a1ec828281c1922b4c819e1e1e01402d4206900105ea181787ea981787ea85e1faa605e1faa605e1faa605e1faa605e1faa1987ea181787ea981787ea85e1faa605e1faa605e1faa60561fac1787ea981787ea981587ea08a181187ea0aa180f87ea086a180987ea88ea980187eb0a6a87ea18c6a1817ac50ae80ca84ea91629a221a8602eb12e27a421a809a8538868988a1803aa578a898ca181285d8c83886a180a85f886838ca02a105f88688888aa02a105fa232025a80a85ba1629a812851a4625a803a849a6621a805a847a7622a09a843a46a983ea148faa007ea23ea8061fa88ba80787eaa16a0361fa881a81187ea22a04e1fa88a81587ea80e1ff6c1921096920a1c19e1e1e01ec828281922b4c81403542069001017b0205e1fb2205e1fb0205e1fb2205e1fb2205e1fb2205e1fb2205e1fb2205e1fb0205e1fb2205e1fb220561fb2205e1fb2205e1fb220561fb41787ec881787ec881587ec18c04e1fb06b0203e1fb061b020261fb272ac80e1fb461aa6b0207ec1996b1cc0817b46bac72a204ec9aea1986a90c080bb469a8e63aa53009b06ba8e65aa4a8430200ec996a998eb116c0813065aa661a8e4a84284b0202c18ea7996a191ea10c02c18ea399ea194a10a10a14c00c186a19a6a1984a845a84300b0728665a8e6194a12a12c04c1ab18ea599e47b003b0b186a598ea390a10a10c01ec2861a8e61aae53009b0728e63a86c983ec18a198ea1b2007ec2c61a86c8061fb0a186a1b00787ec206a86c0361fb0a1b01187ec2ac04e1fb0ab01587ec80e1f809401921096920a1c18f038781ec828281922b4c819e1e1e01503d4206900105ea081787ea881787ea85e1faa205e1faa205e1faa205e1faa205e1faa1987ea081787ea881787ea85e1faa205e1faa205e1faa20561fac1787ea881787ea881587ea10a04e1fa84a8203e1fa841a820261faa43aa0387eb126a081fa8651a819ac61946a0813aa6794ea080daa6d94ea02ea1ce51a82016aa27194ea0812a839c653880a8879ce4fa80a88b9c64da80a88f9c64ba80a88f9c649a8128919c645a803a8919be43a807a8919be42c09a89198ea7846a2466aa007ea23ea8061fa88ba80787ea21ea0361fa881a81187ea22a04e1fa88a81587ea80e1fecc1921096920a1ec828281c1a8bd8f819e1e1e01404542069001017c0205e1fc2205e1fc21787f0881787f0881787f0881787f0881787f08661fc0205e1fc2205e1fc21787f0881787f0881787f0881587f105e1fc2205e1fc220561fc04401387f0130080d87f094640201e1fc2419d000e1fc2439870081fc064398e8c019c447996940204f091e67a0ea402037091e67a16b400bc04599e89acc402017010e69a2eb350081424398e8fa86d390080c0439968ba96d3b003010665a1ea9b06ec00c0519685aa6c5bd002519685a96c9bd00501065a0ea3b1ee5c003c061a0ea3b0eebc007c06a0ea1b06ebc409c085acc1b87078470206b34e1c2007f022b34f420187f0286cbd001e1fc0ab2f400d87f030f401187f03b004e1fc0ec01587f080e1f808501921096920a1ec828281fbc58581fdf91b01b55f180197b86301c012b4819e1e1e01704d4206900105e8081787e8881787e885e1fa2205e1fa2205e1fa2205e1fa2205e1fa21987e8081787e8881787e885e1fa2205e1fa2205e1fa220561fa41787e8881787e8881587e810804e1fa04a0203e1fa041a020261fa243a20387e91268081fa453a019a459a0204e89766a02036897e61a00ba0417e63a020168905f99e808122417e6ba0202817e6fa20a0579e6802814e7fa00a0519fe804813661fe800e812661fe801e81167da409a0439c68784681271a2007e81be88061fa06ba00787e819e80361fa061a01187e81a804e1fa06a01587e880e1feac1921096920a1922b4c81fdf91b019e1e1e0130554206900105e8101787e8901787e885e1fa2405e1fa2405e1fa2405e1fa2405e1fa21987e8101787e8901787e885e1fa2405e1fa2405e1fa240561fa41787e8901787e8901587e818804e1fa06a0403e1fa061a040261fa263a20387e91a68101fa0621be8066918239b681013a26388e698a8100da26988e6588681009a06f88e6188e81005a27388e60966a040489e62d9c8100a0778c67220a0738d661a00a0718de63a00a06d8b6708e7201206b8a66788e62003a06789e6d886801e818e259ce22209a0709669a260fa0609667a2007e808e65a20187e80c65a00787e899680361fa061a01187e81a804e1fa06a01587e880e1ff7c1921096920a1c19e1e1e0197b86301305d420690011ba0406e1fa2406e1fa21b87e8901b87e8901b87e8901b87e8901b87e88761fa0406e1fa2406e1fa21b87e8901b87e8901b87e8901987e90661fa062040561fa072040461fa063a00d87e89968100787e89a622040061fa2698868001fa46b8c6a0406691be31a2a013a06718c68a620402e91d6219a29c81007a07788e60c68c801681d6239a31a31881001a06f89e70c68c72040281ae279c239a3186810020678966189670c63a002067886709e6188663a00a0658c689e6388e65a0120618c60866389e69a003a068c60c68ae6da007a0318318259d6802e80860c608677a20da060c60c6ba2613a029831a68841fa060c67a20587e80a67a00b87e899680461fa061a01587e81a805e1fa06a01987e880e1f808f01921096930a1f16202019e1e1e01ec82828130654206900105e8081787e8881787e885e1fa2205e1fa2205e1fa2205e1fa2205e1fa21987e8081787e8881787e885e1fa2205e1fa2205e1fa220561fa41787e8881787e8881587e810804e1fa04a0203e1fa041a020261fa243a20387e91268081fa453a019a459a0204e89766a02036897e61a00ba0417e63a020168905f99e808122417e6ba0202817e6fa20a0579e6802814e7fa00a0519fe804813661fe800e812661fe801e81167da409a0439c68784681271a2007e81be88061fa06ba00787e819e80361fa061a01187e81a804e1fa06a01587e880e1feac1921096920a1922b4c81fdf91b019e1e1e01306d4206900101ba0206e1fa2206e1fa020761fa0206e1fa2206e1fa2206e1fa2206e1fa21d87e8081b87e8881b87e8881b87e8081b87e8881b87e8881b87e886e1fa2206e1fa41787e81a8081387e81c883e1fa263a0200e1fa0e67a22066879ce885689a41ae41a680811a06194639469a20da263906926126906ba0201e89c641de801681a641a51851a41ae80801a06b9467946da020281b641a41a41a41a41b68080207392e6fa20207393e6da01207193e6da012071926946926ba003a06f9269469269a007a06f92e69a00ba06f91e65a40da07ba1e15a075a2107e81be88161fa06ba00b87e819e80461fa061a01587e81a805e1fa06a01987e880e1f808001921096930a194141401c19e1e1e01307542069001421c43aa5fc2da9edf2e6fc1028082274c62aabd673db3a5a4f2a06c3a55c53b000000000000000000000000000000000000000000000000000000000000000000000000000000000666602080601880380380913d3903803d829020815114023df300091c7238e4555571c78e39aaabc71ce38effff0028013a017b021702f303900445052205c5062ebcb6087f289ed4a1dca2c9e23224a17c8e47ca233284f294f2b32847211e711720d203f2106a79a41c82c80fc84ac661520b2046b99320b204eac96a390a912092057201721a8e44a0587f2a8f281e1fc8a3c80987f2aa6480b87f2ab20361fc8ac80d87f22b20361fc8ac80d87f22b301e1fc8c38cbb2041fcae30ab8cb92821fc8e33022abb2001fc8e3283282ce48007f238c22c288ad2001fcb021030a308c0a48007f239021030a32a3b2021fc9029030a3303920061fc8a44c4328061fcae42c40e480587f2c07281e1fcb1480b87f24320361fc90c80f87f0481187f28461fc805ff418a0f12108a2f5a20182f1530c02faee0002f8c11402fffe4b02eebba782e72a9282f1538e02801642069001066287e30762385e298462d83e2f83e25866238662d84e2002d8362802d82e302278363042383e21822184621806204e1f87e1f96c1830b090b0a2001e4206900136418615946583651b6099066392688079166192681e2598e498202629066390202e71067121188498641813906585649c405e41c41840566190608404641c498404e41c418405671061413996503e63906119c49840567106102101398e41846710e1398650567106884056710614139c418485e61901b9841a206e41a486e6901f9a0c5c1888a8f8a8a9259202a32010029d1b9602202642069001011a860187ea196a001fa86b876a1c21986a056a9a30463a8139c281e72811a860c0b9ca036a1a203e7280baa608139aa02e6184e6a80b9c159aa01e1f886280787e218a0161f8a6280387e29aa0061f8a6a80387e21aa00e1f8a6280387e298a0161f886a80387e298a006b07621aa00a20a14a866218a808106720179aa02504705e6a8028610039aa0566a80286806826a815a86280a861824a815a8700a1844a817aa601e506ea9a11068076a9864a2a07eb1aa20a00e1fac03e641890e908e8a41a0382c7c6bc82c3b10602fa786602dec50902402e420690010f8ae17902190e204629403922100f88501e2120d8a48262120d8a402e2120d8a402e4084021f922021f92210007e4884021f922041f922041f922841f9220061f902100387e50061f922041f9220061f9020061f9020061f9220061f9020061f90206e28064081988480640819920390205e2100392205e21001922066212092286e2143001f90614941888c8f8c8c1219202a51590821036420690010681948183e43a261a4099ce901e6f926220590e679262005a4519e498800e819166390800e85916608610804e51a21842015907086a0139849c418804e61071062015906190620139061928056688690620139c218418418804670861a0139c21a405e68861a0159a21a420179a21a80666886908066218e805e21a418806e21a407621a418420199063a019926a01d9c407649a207e41a854c18a0b0f8b0c3844382ffe47f82dfae5f82fff5ff82303e420690011a9e628e0fac2286620caa0da4622222620c2c09a0624a22a0881a82a07a2220a3283091a82807a0a22222a24c206a0a016918e8088b083062805a4a22720a30830818a04e828608888c18a056828908c20a05e608888630a05e624620a05e622a20630205e620a206a8179881988181788c2263063060562308288301b88828830606e9086206066828830a1a205ec22c281da88988081bb082883021a19b0818c28606ea226281fa26206876a22a981fa8828107ec1806f41888b8e8b8efe95c82c3ae9302e55a4502c1a69d02b51f178299292592025046420690010b90a9a1ba8e6ac139882c6ac6a00d9a81a03a0622a02e62a601e8aa201e62a4036428818087e4206041fa0610087e890107e828107e82a087eb041fa84041f906041f906041fa2107e808087e888087e42a087e42a087e420107e8841fa06021fa0628087e8282021fa82801fa8485640803a415aa202a20685e928e2066622a9003ca41880c0f8c0f8c99282a5159082b51f1782f5cf8902f5d58902404e420690017aa604ea18028810a84ea2042a0faa02022a0d980a00880d9a0280a80d88a8442817a0404eb2011a8120119a02a1188a1a804e21802019a00fa801a00fa86024281198020a04e62a0aa41830889088f6bf5182db31bf82f7505d02c4252f02f75f67024056420690017b6f80f3fda54ce228aa776d43283271853cbadebcbb8751f5ebf3308d22178900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b0c602080601880380380913d3903803d829020815114023df3002405320a640f9614c719f91f2b245c298e2ec033f139233e55438748b84dea531c584d5d7f62b167e26d147246bc79c1abc6ddcc0fd140d672dba4e0d5e607eb39f06af59cfaceffff009401150191024702fd03fa050305fc06b0071907a80853094e09ce0a3d0ab40bc40c4a0cf80e3c0f9a10b31193126112c813be13f9147414b21539161c171317f4187219541a361ad405a2107e8841fa2107e8841fa2287e310007e21061f906007e4387e2a019a41221240da06a20220a06a00fa06a00220206a013a06a066a015a072272017a065a017a069a013a06da00fa071a00da0665a0615a27201fa0720007e8188021fa4107e80061fa019b74180808d0c0aafe780b0afcd8211faee52a11da301742069001012219a219a219a219a219a219a219a219a219a2284e218562384e218562384e2a019a219a219a219a219a217a0418804e81072011a041c803e81261a00da0418e803681063a00da0418e803681063a00f9272011a041c804e81062017a213b141820090090f2ea5a0ad953478adbc11e0afcd8211fa301f4206900101106021f906021f906021f906021f906021f906021f906021f906021f906021f906021f906021f906021f9060a1d8861f88e1d8861f88e1d8a6021f906021f906021f906021f906021f906001fa8906e8296805ea04802a05ea04802a856a0480480568048048056804804805680480480568048048056804a200a213a801a80aa13a8804a04a056a04a04a056a82a04a05ea001fd4418700930b8b4b5350a9a9d9f8a9d8d880ab51f178afcd8211fa402742069001139060787e50a480e1f922392087e48a64001f8840ae487633901d88648a6406e239029901b88e40a6406e239227901d88e4096487623902190e1d8c48a4886407e458c418061f902906622107e439868841f9281a81869021fa06a265a21fa072267a01ba06ba061a017a06fa00206a015a06a272272002217a40a07246a00187e81c80081a80061fa07200206a00187e89a800881e1fa205d041828f8d9008885000afcd8211faa5b49781b55f1801302f420690011ec18061fb141b0087ec516c001fb145b0128e11b06a5430008a40ea03ec216c0b09836c1281b02c0e13928108b040b0384e4304a0c122c0e1592c20c122aa1b906c022877600c3841fb8c188b0107ee30e0481fc80d80187f258e58e580580d81fc803c058087f601648038048e001fb8048e8776007258e036381dd80392d804a17da0581381592821fbc04819d803a0580b804804805817da03c0c96021fb92d80c80187ee00e05207f200e48e052036016076e85207f2012381480787f20120061fd80387f604e1fd80d811f5c18882110e0bf355f180ab55f180abf4ac3bf7374f70aaaa3ebeb6b0ad353530a9f9fba0a9f9fba0aa037420690015e607e1f9a1d87e68761f88e1787e29a20661f8961787e21c285e1f88e0b980387e29a2016618161f8a6806694681e1f9a11a43980987e680612694681e1f9c418e5180387e7146146146041f9c439a4985181f9c419c498e4981598e4198498418419841a41813984b9849841841986418139a479a49c4d981398419849c4b9a518139c51841841a459c41981598518498419c419a4198139a41843986479841981598419841a418e419a51a1398419849c419851c518159851851841849a49a419c139851851c4b9860181594713e707e612610691e7041f9a41a479c0587e691e702e1f98439c0f87e61470561f9c1d87e6001f808281869391938aacafcd8211fa203f42069001c19ee056c100100100106056c10010010010684ec10010010020e1813b0400400800800e04ec1001001002003813b0400400400800e04ec1001001002003813b0400400400400e04ec1001001001001813b0400400800400604ec1001002001001813b0400400800800604ec1001002002001813b0400400800800604ec1001001002001813b0400400400800604ec1002002002003813b040040040043a13b040040040063815b0400400800e05ec10020020e85ec10020020e066c10010018e066c20a18e076c20a381fb0ab81fb0e801fb0e021f80840185808e8b8b51f178aa515908ac121920af8f0550ac1a69d0acaaa6047420690011326158869b011886d846c1cc19cc03ec1acaac9cc02ec1cc286c1cc02ec1ccaac9cc02ec1c430661b00bb2692c986c836c1a4b261b00fb2612c9cc846c92c9a23015b04b268817b0610c9a205ec184326b017b0610c9ac05ec184326b017b0210c98c2019b0e807ec821fb2087ec821fb2087ec821fb2087ec821fb2007ec2ac001faa007ec2ac001faa007ec2ac001fb217d3418780908b8a80a140aaab51f178afadd368afcd8210a95058a8a504f4206900101da4107e9041f928041f8a4821f922821fa05021fa4107e9041fa41da36a05681aea05681aea056818eb18a05681882a62862862815a062062872862815a062c62c62815a06ba815a0ada941818b090c895058a8aaab55f180afcd8211fad632931da405742069001044387e409e406e2b9017902d9015902d90159021902390159031421901590314219015903142190178b6199829901b9825901f982190007e40864001f902190087e60a4041f9860187e680e1f9a0387e680e1f9a0387e680e1f9a0387e680e1f9a0187e41a40061f9a0387e68061f9061060061f9a1fbac185030f0d0a515908a978d8b8ae394948a205f4206900101f0d86f01b96d18e0dc2efb229268270b0f391607c0cbd64581f030f791607c0e3c2c3a64581f0396c40c38683a4382703a8386c40cbc890e09c0ea0e3b1130f140fc0ea0e3c0040e6120fc0e9c0059a11c2e9c0007f039f0187f03883870b9106f0b883cc42ec01dc2e20f3103b007f0b883970021fc0e5c2107f0bb081e1fc41bc4c181020a8f0aafa4f9a9fad632931daf8c9929baf761cd0aa2fa4f9a9f2d632931d27067420690010564980b87e49c0987e41a48261f906120b87e41c281e1f9260860a039c806e4982182827206a01b9260866a066201d942106a0e620007e51880289a107e41ae82e1f9883c0787e6a0e18161f988bac28e00e1f98802e32a380187e6200bacba107e62013cc380987ef30e8261fb8e0987ef30e02e1fbaa3a0987ef30e0261fbcc3a0987eeb0e8261fb8a30e8261fb8a30e8261fb8a30e8261fb8a3c0987ee28c3a0987ee28f0261fb8a3c0987ee30f0261fb8c3a0b87ee30e82e1fb860987ee30e82e1fb8c3a0987ee182e1fbc0b87ee83e1fb807f1c1888f14900cdd6db8acac23f438aecd0330ac7ab1d8aa8188e0afcd8211fa606f42069001818107e6200a06041f988006206041f9881a8180100100100d9001001001881a8182102102102d9021021021881a81801160991601881a818107e6206a06041f988180206041f98802818107e6200387e1f87e1f87e1f87e1f87e1f87e1f87e1f87e1fb8c180878a8e0cdd6db8ac952d80afcd8211daa320100a3077420690010218662585627856818a15a0e15906684e51849a11928985180f9081889a4180fa0610818890603e6126106604e620419813916604e500420604e498010818119260242060464980908181190604884e1facc18100898a0fcd8211fad4258f19afa4f9a9dad1e0438a307f420690019961391e1389e1399e15b241856c385681aa13a4a22a8468b2a24a03e830a32aa0a03ec28830a328280fa88a881a813a8c206a04e85a813a4020c2813a2a00830a0468a80a0c2811a2a02830a0468281321db013ae4182808a0a0fcd8211fad4258f19afa4f9a9daec82828a922b4c8aca50874206900102e608505e50a6001f9821061390e2981d98210e13916298199821161391e298178845981398478a604e2116605e611e2980f8845981b9847980f9847981d984398139a43981f98518c056c1a498087e6106288056c2a7021f9aaa0c046c20b300187ec2cc046c20a18061fb0b20c036c20b300587ec2c8300bb0a1b00587ec286c026c20a18261fb0a1b007b0a1b00987ec286c01e8286c02e1fb0a1b001b2a1b00f87ec28c2ac02c288aac8461fb0a20a20c00c28c2ac2ac0361fb0a3b4a30a30a30a300d87ec2ac28c28c02c28c2ac83e1fb2a30a3003b0a301387ec2ac28c016c05e1fb0a320387e1fb001ffc1868c8d170b9a184992fcd8211f2e72a929d2a2b55f18029f320c82508f420690010da0e11a0259080362990802680ae42007a02b90801e8086608e801e80c7086801e80c9086801e80c90c420098ae402e809e4200da0239080468086804e80c42013a0310805680842017a0619a21ba21ba21ba21ba21ba21ba21ba2199889819a21ba2199889819a203b74184098f098b08e280a8f03878aebbddd0af193550a3097420690016a180587ea180587ea180587ea180587ea180587ea180587ea180587ea180587ea182841f8860187e23841f8860187e23841f8a60161fa860161fa860161fa860161fa860161fa860161fa868061fa8620a18087ea1892a1fa8620ea201da8620ea201da8620ea201da8620ea201da8620ea201da8620ea201da8620ea201fa8624a20087ea1882a0187eb001fc9c18283900d8ecd0330af0dac48adbc11e0aefd8408afcd8211fa409f42069001dc1e01c455c21bc2e7c4c1b113f018670bcc3b9030e18f40e21513b005f0bac18ed42c18e7c06e5c015c0eb06b066b30b06386d38c1ac38f004703a6b4eb26bb0b06386c1ac38ed39003703a634e7b2f42f398d39002f038632ffc0e5c4e18cb900270386bcffc2632f44e18ec007c0e3c16f7c2634f426bb000f038701bacbc6d3b098d3d01aec001c0ec06eb06baf05b2ec46b2e4263b08503913a6b4e5c405c0634e4481c0603c4e9ad3970837038632e42a1a009c2e98d39f004f098c3b12c09c0eb4e7c219c06390a0b02703acb9f087f1028280bc0e32e7c0107f0057038c39708761fc0e9c21f87f03b05801f87f03b00261f87f08461f87e1f87e1f87e1f87e1f87e1f87e1f87e1f87e1f87e1f87e1f87e1f87e1f809901828a90188aaff80000aff9c1c0afcd8211fadec50919affb5b58aa2a2a28a9212120a70a7420690011587f078261f87f098f08161f87f019059908061f87f0191050990821f87f019100f0190801f87f0191017019087e1fc064407c06420d87f100f0191027019082e1fc0e4b005019102701910261fc0e4803924004064409c06440987f03924203b0191027019102f1056840e31448050040e0bc06420bc464011a0a40c00c500c0ac20dc064209c464011a0ac20314004084420fc064207c464011a0ac0ac141221021011c064205c464011c0ac0a1c2408485701807119004702b029e48817c0642664011c0ac0ab901bc067c013c0aa0adc01dc1e15c0ac0abc0087e1fc0b40a7c00187e1fc0b18a3c00587e1fc4a20b401f87ee49400744b029029007e1fb90c9403440ed0ac0007e1fc90d0c52c39049442107e1fd0cd0c39439481e1f87f4c12c12500d87e1fd0e0787e1f80a801808b8e9b0acacac8ad353530aaae363630aebeb6b0aff80000aaaa5a59a0afcd8211fadec50919a90af420690010f8a0d87e848202e1fa12200b87f2a00d87f2200f87f2200f87f2200f87f28361f9b21a0b87f29060261f9a810602e1fc88106100787e6c871130061fca09b14a087f285240f2001fcc04903b920572183301240ee4c0fc901c80a12012406e490c80dc905c8022c406a4901c80bc8e406a45244ac17203723aa1cb01a9240ee480fcb0c90a90cd01bb203f240f2a904903bb284724072032412432384f23914a04b04914819c8ec32012406a4520672312832406a4072001fc90b90a903c81fc9039128e407207f23901c8e44c001fc8e40723b0c8007f23914d0390041fc91480cc0187f3021f8081018400911008042800a805b800ab76f370a8045000a8063800a8030800afcd8210adec5090aa41a038a80b742069001f982782e25980187e609e0d89e6041f982584660966001f982598139825981d982598179831a007e68c606e6086126076612688607661066066610e6001f98419817984198087e61066056610660061f98419813985180587e6106603e6106601e1f9841980d985180987e610e60266106602e1f984398059841980f87e6106600e610e603e1f9a419811841841c0f87e61261261060061461460361f9849841a49a4184184184180d87e69261270061061061060461f984184184981185181587e614680e70661f9c01ec41850c8b180a2fcd8211f294b2e70a20bf4206900117a98161fe960b87fa500f87fa500b87e40b40361f93402e1f902d00d87e4d040261f902920b87e4094100d87fa8361fe8e6a0987fa28f6a0387fa28e1aba041fe8a396ae8007fa3aeae81de8a3b6ae81be8e1a86ea8e29a067a38b1e0a5015e9828e2a69a0e60a6813e8f4b468f4612b1851a03fa60e51a1cd0c9a1c94680fe946576567ea13e8f8dea1febe19cbc181808c900b4b5350aeffb648aeb71e50acccd4d0ae3f1558ae4ed5c8ad1e0438ad86bc48abc599e8ad1e4bf0ad1e83b0afcd8210adec5090ac0c74206900122d866278262f8662b80e318662f842382e1f89e08c1387e2580305e1f88608a1987e218028661f88600c1787e30428561f886108e0f87e300e2382e1f8860388e0987e2181e2180e1f89e098a0587e2387e1f886007e1f8c03a7c1850b88950aa00cf4206900101d90e1187e498e4184e611e01926f920d98419e4180127590099260867907d90079829166906192661906900798402669407947106901187e40861901387e6086906101387e4086106901387e41a418404e1f926106101387e6106906101187e61061901187e6127101187e21841c403e1f8869061900d87e21a418e402e1f8869063900b87e618861900987e41862186401e1f8860070861900787e61001a00861900787e6007002186402e1f984022186402e1f90118e40461f8863900f87e210018640361f9840021801a40461f8861001a40461f9011840661f9817541871010130e3949485ba8d0d05fe81010520d742069001483e49a49801061001849a641841ae480418400498e402e498404e406e1f87e1f87e1f87e1f9441808408078a59e1e1e05b4b5350520df4206900101990670261f89650161f94e2076419a09c45880d9c459c0398e5080392689e704641880192e705e61220461f984881387e6121387e6121387e6121387e61220461f984881187e6004081187e6006080f87e602600404e1f980101987e40561f87e1fb141808f0a118effb6485de71cb05ca65ae8520e74206900194601922902902902920102102902902902902122920120120122900120f921787e1f87e1f87e1f87e1f87e1f9941808488888a5f301010510ef420690015b48b0621b06306021fa0c1a8d18ca0630a32007e834a34634630a328b40d87e214c2cd201187e430620a20622c28c02e1f90c1883023080461f908188302301387e4302b4804e1fb28281987ec18828504e1fb0818c0661fb21d87e828c87e1f87e1f87e1fb941808d08130b6988a05cdb31205a5ebd91c05b9a18485c7b3ab0550f74206900101f906007e4797e199429265f83e48a50de4988502e4588558c478a4826438a50264b8a4188482e4583e50441884188502643846480e508418850265041f922142141787e48850848661f902142121987e48848850661f922102141987e488488505e1f922122141987e40848850661f902142121987e488488505e1f922122141787e488508485e1f942122121787e508488485e1f942122121787e508488485e1f9421061987e498661f92e1987e50040240661f940120121787e40048040761f92010087e1f90010087e1f9007edc1880f10958a807af85fcd8210510ff4206900139ee0387e69fe087e6591e7186e68a69467383e68841a48b650a6394702e6588778a678a682e6188618266b8a6188682e6583e618261886188702663846680e708618870267041f9a21c21c1787e68871068661f9821068868661f9a21a21c1987e68860870661f9a21a21c1787e68868841a1987e60868841a1987e60870868661f9a21a21c1787e688710685e1f9a21c41a1787e7086884181787e7086884181787e7086884181787e69021a21a1787e69021a2181987e69070860661f9a41961987e70060260661f9c01a01a1787e60068060761f9a018087e1f980180d87e1ff941880f11158a5bf2e1005ecd83305210742069001b87e618561f9961187e6982e1f982b980787e608611e608600e1f98218419e418218107e60861070261906589e67846086100798e01c212e219862920998e01a2106790631a2920b9a01801d650c6120f980180980d9865086846686e69421a1198007e6102981787e61021a1787e40a685e1f9029a1587e48a684e1f9840a684e1f9a408704e1f98408704e1f9a40868561f9840868561f9840868561f98408684e1f9a41a1387e710683e1f99e0d87e698361f98019861187e658461f9c01c0f87e604705e1f9a1b87e1fea41860f91930e39494859f9fba05c5210f4206900106a5836a9aa08059062a61a86702a98ea182808a9a05a4408a80663a8200808a1a05a88aa41860790a00818a18a04a18881a82a61806610a80828628e202622c63a042820290c1388b2428161fac28361f87e1f87e1f87e1f87e1f87e1fb2c18088078f8f6bf5185d496ab05f75f6705ca14a605f11b38054117420690011e1f87ec04c01e1fa0c02a324180a0c04ec00a90c20c10ab24188288300fb0432a90c20c10ab2418828830a300bb0434ab0832a30830620a30830a3007b0630830630a888b28102288308b0a30a00c02c00c18c20c22c88420230810228c20432830a320b0630422ca2c08420202280810ca0c90c18c00c18d22303e2a0430a10c18c00c90a304241388808c190c02d0861588662a4300b04207081988c384c90906e22443001b2306ea30605b042a1b88a12c016c8a1db41d87e1f87e1f87e1ff5c180888a900c7851585f6db6405e2851585ef626685c5bc051585511f420690011e1f87ec04c01e1fa0c02a324180a0c04ec00a90c20c10ab24188288300fb0432a90c20c10ab2418828830a300bb0434ab0832a30830620a30830a3007b0630830630a888b28102288308b0a30a00c02c00c18c20c22c88420230810228c20432830a320b0630422ca2c08420202280810ca0c90c18c00c18d22303e2a0430a10c18c00c90a304241388808c190c02d0861588662a4300b04207081988c384c90906e22443001b2306ea30605b042a1b88a12c016c8a1db41d87e1f87e1f87e1ff5c180888a900c1219205f75f6705ec6f7485f761cd05c5b51f17855127420690010206048021fa0600620087e81868021fa2720007ea20710807ea20710807691c807e8184a0a07e814620a07e81868021fa061a0007e818682a6902ea20692828e43a2a1001aa810682ae522a04a82ea10a246948281fa049a8281fa041868001fa041a0087e818520087e8180188041fa01200187e1f87e1f87e1f87e1fc5c1808a0d8d0bd0f9e85f6bf5185d496ab05cb932585f2a43e05412f4206900109d3cced92a5590024f56006fceea2ebe8e3a2707bcf175efdbae6bbc18920330000000000000000000000000000000000000000";

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

library ShiftLib {
    /// @notice creates a bit mask
    /// @dev res = (2 ^ bits) - 1
    /// @param bits d
    /// @return res d
    /// @dev no need to check if "bits" is < 256 as anything greater than 255 will be treated the same
    function mask(uint8 bits) internal pure returns (uint256 res) {
        assembly {
            res := sub(shl(bits, 1), 1)
        }
    }

    function fullsubmask(uint8 bits, uint8 pos) internal pure returns (uint256 res) {
        res = ~(mask(bits) << pos);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {ShiftLib} from "../libraries/ShiftLib.sol";

/// @title DotnuggV1Reader
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @notice a library encoded/decoding color and other pixel related data
library DotnuggV1Pixel {
    function rgba(uint256 input) internal pure returns (uint256 res) {
        unchecked {
            return ((input << 5) & 0xffffff_00) | a(input);
        }
    }

    function unsafePack(
        uint256 _rgb,
        uint256 _a,
        uint256 _id,
        uint256 _zindex,
        uint256 _feature
    ) internal pure returns (uint256 res) {
        unchecked {
            res |= (_feature & 0x7) << 39;
            res |= (_zindex & 0xf) << 35;
            res |= (_id & 0xff) << 27;
            res |= _rgb << 3;
            res |= compressA(_a & 0xff);
        }
    }

    function unsafeGraft(
        uint256 base,
        uint256 _id,
        uint256 _zindex,
        uint256 _feature
    ) internal pure returns (uint256 res) {
        unchecked {
            res = base & ShiftLib.mask(27);
            res |= (_feature & 0x7) << 39;
            res |= (_zindex & 0xf) << 35;
            res |= (_id & 0xff) << 27;
        }
    }

    function r(uint256 input) internal pure returns (uint256 res) {
        res = (input >> 19) & 0xff;
    }

    function g(uint256 input) internal pure returns (uint256 res) {
        res = (input >> 11) & 0xff;
    }

    function b(uint256 input) internal pure returns (uint256 res) {
        res = (input >> 3) & 0xff;
    }

    // 3 bits
    function a(uint256 input) internal pure returns (uint256 res) {
        res = ((input & 0x7) == 0x7 ? 255 : ((input & 0x7) * 36));
    }

    // this is 1-8 so 3 bits
    function id(uint256 input) internal pure returns (uint256 res) {
        res = (input >> 27) & 0xff;
    }

    // 18 3,3,4 && 8
    // this is 1-16 so 4 bits
    function z(uint256 input) internal pure returns (uint256 res) {
        res = (input >> 35) & 0xf;
    }

    // this is 1-8 so 3 bits
    function f(uint256 input) internal pure returns (uint256 res) {
        res = (input >> 39) & 0x7;
    }

    /// @notice check for if a pixel exists
    /// @dev for a pixel to exist a must be > 0, so we can safely assume that if we see
    /// no data it is empty or a transparent pixel we do not need to process
    function e(uint256 input) internal pure returns (bool res) {
        res = input != 0x00;
    }

    /// @notice converts an 8 bit (0-255) value into a 3 bit value (0-7)
    /// @dev a compressed value of 7 is equivilent to 255, and a compressed 0 is 0
    function compressA(uint256 input) internal pure returns (uint256 res) {
        return input / 36;
    }

    function combine(uint256 base, uint256 mix) internal pure returns (uint256 res) {
        unchecked {
            if (a(mix) == 255 || a(base) == 0) {
                res = mix;
                return res;
            }
            // FIXME - i am pretty sure there is a bug here that causes the non-color pixel data to be deleted
            res |= uint256((r(base) * (255 - a(mix)) + r(mix) * a(mix)) / 255) << 19;
            res |= uint256((g(base) * (255 - a(mix)) + g(mix) * a(mix)) / 255) << 11;
            res |= uint256((b(base) * (255 - a(mix)) + b(mix) * a(mix)) / 255) << 3;
            res |= 0x7;
            res |= (mix >> 27) << 27;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {DotnuggV1Parser as Parser} from "./DotnuggV1Parser.sol";

/// @title DotnuggV1Matrix
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @notice implementation of a 2D array used in combination of dotnugg files
library DotnuggV1Matrix {
    using Parser for Parser.Memory;

    struct Memory {
        uint8 width;
        uint8 height;
        Parser.Memory version;
        uint8 currentUnsetX;
        uint8 currentUnsetY;
        bool init;
        uint8 startX;
    }

    function create(uint8 width, uint8 height) internal pure returns (Memory memory res) {
        require(width % 2 == 1 && height % 2 == 1, "ML:C:0");

        res.version.initBigMatrix(width);
        res.version.setWidth(width, height);
    }

    function moveTo(
        Memory memory matrix,
        uint8 xoffset,
        uint8 yoffset,
        uint8 width,
        uint8 height
    ) internal pure {
        matrix.currentUnsetX = xoffset;
        matrix.currentUnsetY = yoffset;
        matrix.startX = xoffset;
        matrix.width = width + xoffset;
        matrix.height = height + yoffset;
    }

    function next(Memory memory matrix) internal pure returns (bool res) {
        res = next(matrix, matrix.width);
    }

    function next(Memory memory matrix, uint8 width) internal pure returns (bool res) {
        unchecked {
            if (matrix.init) {
                if (width <= matrix.currentUnsetX + 1) {
                    if (matrix.height == matrix.currentUnsetY + 1) {
                        return false;
                    }
                    matrix.currentUnsetX = matrix.startX; // 0 by default
                    matrix.currentUnsetY++;
                } else {
                    matrix.currentUnsetX++;
                }
            } else {
                matrix.init = true;
            }
            res = true;
        }
    }

    function current(Memory memory matrix) internal pure returns (uint256 res) {
        res = matrix.version.getBigMatrixPixelAt(matrix.currentUnsetX, matrix.currentUnsetY);
    }

    function setCurrent(Memory memory matrix, uint256 pixel) internal pure {
        matrix.version.setBigMatrixPixelAt(matrix.currentUnsetX, matrix.currentUnsetY, pixel);
    }

    function resetIterator(Memory memory matrix) internal pure {
        matrix.currentUnsetX = 0;
        matrix.currentUnsetY = 0;
        matrix.startX = 0;
        matrix.init = false;
    }

    function moveBack(Memory memory matrix) internal pure {
        (uint256 width, uint256 height) = matrix.version.getWidth();
        matrix.width = uint8(width);
        matrix.height = uint8(height);
    }

    function set(
        Memory memory matrix,
        Parser.Memory memory data,
        uint256 groupWidth,
        uint256 groupHeight
    ) internal pure {
        unchecked {
            matrix.height = uint8(groupHeight);

            for (uint256 y = 0; y < groupHeight; y++) {
                for (uint256 x = 0; x < groupWidth; x++) {
                    next(matrix, uint8(groupWidth));
                    uint256 col = data.getPixelAt(x, y);
                    if (col != 0) {
                        (uint256 yo, , ) = data.getPalletColorAt(col);

                        setCurrent(matrix, yo);
                    } else {
                        setCurrent(matrix, 0x0000000000);
                    }
                }
            }

            matrix.width = uint8(groupWidth);

            resetIterator(matrix);
        }
    }

    function addRowsAt(
        Memory memory matrix,
        uint8 index,
        uint8 amount
    ) internal pure {
        unchecked {
            for (uint256 i = 0; i < matrix.height; i++) {
                for (uint256 j = matrix.height; j > index; j--) {
                    if (j < index) break;
                    matrix.version.setBigMatrixPixelAt(i, j + amount, matrix.version.getBigMatrixPixelAt(i, j));
                }
                // "<=" is because this loop needs to run [amount] times
                for (uint256 j = index + 1; j <= index + amount; j++) {
                    matrix.version.setBigMatrixPixelAt(i, j, matrix.version.getBigMatrixPixelAt(i, index));
                }
            }
            matrix.height += amount;
        }
    }

    function addColumnsAt(
        Memory memory matrix,
        uint8 index,
        uint8 amount
    ) internal pure {
        unchecked {
            // require(index < matrix.data[0].length, 'MAT:ACA:0');
            for (uint256 i = 0; i < matrix.width; i++) {
                for (uint256 j = matrix.width; j > index; j--) {
                    if (j < index) break;
                    matrix.version.setBigMatrixPixelAt(j + amount, i, matrix.version.getBigMatrixPixelAt(j, i));
                }
                // "<=" is because this loop needs to run [amount] times
                for (uint256 j = index + 1; j <= index + amount; j++) {
                    matrix.version.setBigMatrixPixelAt(j, i, matrix.version.getBigMatrixPixelAt(index, i));
                }
            }
            matrix.width += amount;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {ShiftLib} from "../libraries/ShiftLib.sol";

import {DotnuggV1Pixel as Pixel} from "./DotnuggV1Pixel.sol";
import {DotnuggV1Reader as Reader} from "./DotnuggV1Reader.sol";

/// @title DotnuggV1Parser
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @notice a library decoding DotnuggV1 encoded data files
library DotnuggV1Parser {
    using Reader for Reader.Memory;
    using Pixel for uint256;

    struct Memory {
        Reader.Memory reader;
        uint256[] pallet;
        uint256[] minimatrix;
        uint256[] bigmatrix;
        uint256 receivers;
        uint256 data;
        uint256 bitmatrixptr;
        uint8 palletBitLen;
        bool exists;
    }

    function parse(uint256[][] memory reads) internal pure returns (Memory[8] memory m, uint256 len) {
        unchecked {
            for (uint256 j = 0; j < reads.length; j++) {
                (bool empty, Reader.Memory memory reader) = Reader.init(reads[j]);

                if (empty) continue;

                // indicates dotnuggV1 encoded file
                require(reader.select(32) == 0x420690_01, "0x42");

                uint256 feature = reader.select(3);

                if (m[feature].exists) continue;

                len++;

                m[feature].exists = true;
                m[feature].reader = reader;
            }

            uint256[] memory graftPallet;

            for (uint256 feature = 0; feature < 8; feature++) {
                if (!m[feature].exists) continue;

                uint256 id = m[feature].reader.select(8);

                m[feature].palletBitLen = uint8((m[feature].reader.select(1) * 4) + 4);

                uint256[] memory pallet = parsePallet(m[feature], id, feature, graftPallet);

                if (m[feature].reader.select(1) == 1) {
                    require(graftPallet.length == 0, "0x34");
                    graftPallet = pallet;
                }

                uint256 versionLength = m[feature].reader.select(2) + 1;

                require(versionLength == 1, "UNSUPPORTED_VERSION_LEN");

                m[feature].data = parseData(m[feature].reader, feature);

                m[feature].receivers = parseReceivers(m[feature].reader);

                (uint256 width, uint256 height) = getWidth(m[feature]);

                m[feature].minimatrix = parseMiniMatrix(m[feature], width, height);

                m[feature].pallet = pallet;
            }
        }
    }

    function parsePallet(
        Memory memory parser,
        uint256 id,
        uint256 feature,
        uint256[] memory graftPallet
    ) internal pure returns (uint256[] memory res) {
        unchecked {
            uint256 palletLength = parser.reader.select(parser.palletBitLen) + 1;

            res = new uint256[](palletLength + 1);

            for (uint256 i = 0; i < palletLength; i++) {
                // 4 bits: zindex
                uint256 z = parser.reader.select(4);

                uint256 color;

                uint256 graftIndex = parser.reader.select(1);
                if (graftIndex == 1) graftIndex = parser.reader.select(4);

                uint256 isBlack = parser.reader.select(1);
                uint256 isWhite = parser.reader.select(1);

                if (isWhite == 1) {
                    color = 0xffffff;
                } else if (isBlack == 1) {
                    color = 0x000000;
                } else {
                    color = parser.reader.select(24);
                }

                // // 1 or 8 bits: a
                uint256 a = (parser.reader.select(1) == 0x1 ? 0xff : parser.reader.select(8));

                if (graftIndex != 0 && graftPallet.length > graftIndex) {
                    res[i + 1] = Pixel.unsafeGraft(graftPallet[graftIndex], id, z, feature);
                } else {
                    res[i + 1] = Pixel.unsafePack(color, a, id, z, feature);
                }
            }
        }
    }

    uint8 constant DATA_FEATURE_OFFSET = 95;
    uint8 constant DATA_WIDTH_OFFSET = 67;
    uint8 constant DATA_HIEGHT_OFFSET = 75;
    uint8 constant DATA_X_ANCHOR_OFFSET = 51;
    uint8 constant DATA_Y_ANCHOR_OFFSET = 59;
    uint8 constant DATA_RADII_OFFSET = 128;
    uint8 constant DATA_COORDINATE_BIT_LEN = 8;
    uint8 constant DATA_COORDINATE_BIT_LEN_2X = 16;
    uint8 constant DATA_RLUD_LEN = DATA_COORDINATE_BIT_LEN * 4;

    function parseData(Reader.Memory memory reader, uint256 feature) internal pure returns (uint256 res) {
        // 12 bits: coordinate - anchor x and y
        unchecked {
            res |= feature << DATA_FEATURE_OFFSET;

            uint256 width = reader.select(DATA_COORDINATE_BIT_LEN);
            uint256 height = reader.select(DATA_COORDINATE_BIT_LEN);

            res |= height << DATA_HIEGHT_OFFSET;
            res |= width << DATA_WIDTH_OFFSET;

            uint256 anchorX = reader.select(DATA_COORDINATE_BIT_LEN);
            uint256 anchorY = reader.select(DATA_COORDINATE_BIT_LEN);

            res |= anchorX << DATA_X_ANCHOR_OFFSET;
            res |= anchorY << DATA_Y_ANCHOR_OFFSET;

            // 1 or 25 bits: rlud - radii
            res |= (reader.select(1) == 0x1 ? 0 : reader.select(DATA_RLUD_LEN)) << DATA_RADII_OFFSET;

            // 1 or 25 bits: rlud - expanders
            res |= (reader.select(1) == 0x1 ? 0 : reader.select(DATA_RLUD_LEN)) << 3;
        }
    }

    function parseReceivers(Reader.Memory memory reader) internal pure returns (uint256 res) {
        unchecked {
            uint256 receiversLength = reader.select(1) == 0x1 ? 0x1 : reader.select(4);

            for (uint256 j = 0; j < receiversLength; j++) {
                uint256 receiver = 0;

                uint256 yOrYOffset = reader.select(DATA_COORDINATE_BIT_LEN);

                uint256 xOrPreset = reader.select(DATA_COORDINATE_BIT_LEN);

                // rFeature
                uint256 rFeature = reader.select(3);

                uint256 calculated = reader.select(1);

                if (calculated == 0x1) {
                    receiver |= yOrYOffset << DATA_COORDINATE_BIT_LEN;
                    receiver |= xOrPreset;
                } else {
                    receiver |= xOrPreset << DATA_COORDINATE_BIT_LEN;
                    receiver |= yOrYOffset;
                }

                receiver <<= ((rFeature * DATA_COORDINATE_BIT_LEN_2X) + (calculated == 0x1 ? 128 : 0));

                res |= receiver;
            }
        }
    }

    function parseMiniMatrix(
        Memory memory parser,
        uint256 height,
        uint256 width
    ) internal pure returns (uint256[] memory res) {
        unchecked {
            uint8 miniMatrixSizer = uint8(256 / parser.palletBitLen);
            uint256 groupsLength = parser.reader.select(1) == 0x1
                ? parser.reader.select(8) + 1
                : parser.reader.select(16) + 1;

            res = new uint256[]((height * width) / miniMatrixSizer + 1);

            uint256 index = 0;

            for (uint256 a = 0; a < groupsLength; a++) {
                uint256 len = parser.reader.select(2) + 1;

                if (len == 4) len = parser.reader.select(4) + 4;

                uint256 key = parser.reader.select(parser.palletBitLen);

                for (uint256 i = 0; i < len; i++) {
                    res[index / miniMatrixSizer] |= (key << (parser.palletBitLen * (index % miniMatrixSizer)));
                    index++;
                }
            }
        }
    }

    function getReceiverAt(
        Memory memory m,
        uint256 index,
        bool calculated
    )
        internal
        pure
        returns (
            uint256 x,
            uint256 y,
            bool exists
        )
    {
        unchecked {
            uint256 data = m.receivers >> (index * DATA_COORDINATE_BIT_LEN_2X + (calculated ? 128 : 0));

            data &= ShiftLib.mask(DATA_COORDINATE_BIT_LEN_2X);

            x = data & ShiftLib.mask(DATA_COORDINATE_BIT_LEN);
            y = data >> DATA_COORDINATE_BIT_LEN;

            exists = x != 0 || y != 0;
        }
    }

    function setReceiverAt(
        Memory memory m,
        uint256 index,
        bool calculated,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 res) {
        unchecked {
            // yOrYOffset
            res |= y << DATA_COORDINATE_BIT_LEN;

            //xOrPreset
            res |= x;

            m.receivers |= res << ((index * DATA_COORDINATE_BIT_LEN_2X) + (calculated ? 128 : 0));
        }
    }

    function getRadii(Memory memory m) internal pure returns (uint256 res) {
        unchecked {
            res = (m.data >> DATA_RADII_OFFSET) & ShiftLib.mask(DATA_RLUD_LEN);
        }
    }

    function getExpanders(Memory memory m) internal pure returns (uint256 res) {
        unchecked {
            res = (m.data >> 3) & ShiftLib.mask(DATA_RLUD_LEN);
        }
    }

    function setFeature(Memory memory m, uint256 z) internal pure {
        unchecked {
            require(z <= ShiftLib.mask(3), "VERS:SETF:0");
            m.data &= ShiftLib.fullsubmask(3, DATA_FEATURE_OFFSET);
            m.data |= (z << DATA_FEATURE_OFFSET);
        }
    }

    function getFeature(Memory memory m) internal pure returns (uint256 res) {
        unchecked {
            res = (m.data >> DATA_FEATURE_OFFSET) & ShiftLib.mask(3);
        }
    }

    function getWidth(Memory memory m) internal pure returns (uint256 width, uint256 height) {
        unchecked {
            // yOrYOffset
            width = (m.data >> DATA_WIDTH_OFFSET) & ShiftLib.mask(DATA_COORDINATE_BIT_LEN);
            height = (m.data >> DATA_HIEGHT_OFFSET) & ShiftLib.mask(DATA_COORDINATE_BIT_LEN);
        }
    }

    function setWidth(
        Memory memory m,
        uint256 w,
        uint256 h
    ) internal pure {
        unchecked {
            require(w <= ShiftLib.mask(DATA_COORDINATE_BIT_LEN), "VERS:SETW:0");
            require(h <= ShiftLib.mask(DATA_COORDINATE_BIT_LEN), "VERS:SETW:1");

            m.data &= ShiftLib.fullsubmask(DATA_COORDINATE_BIT_LEN_2X, DATA_WIDTH_OFFSET);

            m.data |= (w << DATA_WIDTH_OFFSET);
            m.data |= (h << DATA_HIEGHT_OFFSET);
        }
    }

    function getAnchor(Memory memory m) internal pure returns (uint256 x, uint256 y) {
        unchecked {
            // yOrYOffset
            x = (m.data >> DATA_X_ANCHOR_OFFSET) & ShiftLib.mask(DATA_COORDINATE_BIT_LEN);
            y = (m.data >> DATA_Y_ANCHOR_OFFSET) & ShiftLib.mask(DATA_COORDINATE_BIT_LEN);
        }
    }

    function getPixelAt(
        Memory memory m,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 palletKey) {
        unchecked {
            uint8 miniMatrixSizer = uint8(256 / m.palletBitLen);

            (uint256 width, ) = getWidth(m);
            uint256 index = x + (y * width);

            if (index / miniMatrixSizer >= m.minimatrix.length) return 0x0;

            palletKey =
                (m.minimatrix[index / miniMatrixSizer] >> (m.palletBitLen * (index % miniMatrixSizer))) &
                ShiftLib.mask(m.palletBitLen);
        }
    }

    function getPalletColorAt(Memory memory m, uint256 index)
        internal
        pure
        returns (
            uint256 res,
            uint256 color,
            uint256 zindex
        )
    {
        unchecked {
            // res = (m.pallet[index / 7] >> (36 * (index % 7))) & ShiftLib.mask(36);
            res = m.pallet[index];

            color = Pixel.rgba(res);

            zindex = Pixel.z(res);
        }
    }

    function initBigMatrix(Memory memory m, uint256 width) internal pure {
        unchecked {
            m.bigmatrix = new uint256[](((width * width) / 6) + 2);
        }
    }

    function setBigMatrixPixelAt(
        Memory memory m,
        uint256 x,
        uint256 y,
        uint256 color
    ) internal pure {
        unchecked {
            (uint256 width, ) = getWidth(m);

            uint256 index = x + (y * width);

            setBigMatrixPixelAt(m, index, color);
        }
    }

    function setBigMatrixPixelAt(
        Memory memory m,
        uint256 index,
        uint256 color
    ) internal pure {
        unchecked {
            if (m.bigmatrix.length > index / 6) {
                uint8 offset = uint8(42 * (index % 6)); // NOTE: i removed safe8
                m.bigmatrix[index / 6] &= ShiftLib.fullsubmask(42, offset);
                m.bigmatrix[index / 6] |= (color << offset);

                assembly {

                }
            }
        }
    }

    function getBigMatrixPixelAt(
        Memory memory m,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 res) {
        unchecked {
            (uint256 width, ) = getWidth(m);

            (res, ) = getPixelAt(m.bigmatrix, x, y, width);
        }
    }

    function getPixelAt(
        uint256[] memory arr,
        uint256 x,
        uint256 y,
        uint256 width
    ) internal pure returns (uint256 res, uint256 row) {
        unchecked {
            uint256 index = x + (y * width);

            if (index / 6 >= arr.length) return (0, 0);

            row = (arr[index / 6] >> (42 * (index % 6)));

            res = row & ShiftLib.mask(42);
        }
    }

    function bigMatrixHasPixelAt(
        Memory memory m,
        uint256 x,
        uint256 y
    ) internal pure returns (bool res) {
        unchecked {
            uint256 pix = getBigMatrixPixelAt(m, x, y);

            res = pix & 0x7 != 0x00;
        }
    }

    function setArrayLength(uint256[] memory input, uint256 size) internal pure {
        assembly {
            let ptr := mload(input)
            ptr := size
            mstore(input, ptr)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import {ShiftLib} from "../libraries/ShiftLib.sol";

/// @title DotnuggV1Reader
/// @author nugg.xyz - danny7even and dub6ix - 2022
/// @notice a library for reading DotnuggV1 encoded data files
library DotnuggV1Reader {
    using ShiftLib for uint256;

    struct Memory {
        uint256[] dat;
        uint256 moves;
        uint256 pos;
    }

    function init(uint256[] memory input) internal pure returns (bool err, Memory memory m) {
        unchecked {
            if (input.length == 0) return (true, m);

            m.dat = input;

            m.moves = 2;

            m.dat = new uint256[](input.length);

            for (uint256 i = input.length; i > 0; i--) {
                m.dat[i - 1] = input[input.length - i];
            }
        }
    }

    function peek(Memory memory m, uint8 bits) internal pure returns (uint256 res) {
        res = m.dat[0] & ShiftLib.mask(bits);
    }

    function select(Memory memory m, uint8 bits) internal pure returns (uint256 res) {
        unchecked {
            res = m.dat[0] & ShiftLib.mask(bits);

            m.dat[0] = m.dat[0] >> bits;

            m.pos += bits;

            if (m.pos >= 128) {
                uint256 ptr = (m.moves / 2);
                if (ptr < m.dat.length) {
                    m.dat[0] <<= m.pos - 128;
                    uint256 move = m.dat[ptr] & ShiftLib.mask(128);
                    m.dat[ptr] >>= 128;
                    m.dat[0] |= (move << 128);
                    m.dat[0] >>= (m.pos - 128);
                    m.moves++;
                    m.pos -= 128;
                }
            }
        }
    }
}