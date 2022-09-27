/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IERC721
{
    function setApprovalForAll(address operator, bool _approved) external;
}

contract TestListSeaport
{
	struct EIP712Domain {
		string  name;
		string  version;
		uint256 chainId;
		address verifyingContract;
	}

	struct OrderComponents {
		address offerer;
		address zone;
		OfferItem[] offer;
		ConsiderationItem[] consideration;
		uint8 orderType;
		uint256 startTime;
		uint256 endTime;
		bytes32 zoneHash;
		uint256 salt;
		bytes32 conduitKey;
		uint256 counter;
	}

	struct OfferItem {
		uint8 itemType;
		address token;
		uint256 identifierOrCriteria;
		uint256 startAmount;
		uint256 endAmount;
	}

	struct ConsiderationItem {
		uint8 itemType;
		address token;
		uint256 identifierOrCriteria;
		uint256 startAmount;
		uint256 endAmount;
		address recipient;
	}

	bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
	bytes32 constant ORDERCOMPONENTS_TYPEHASH = keccak256("OrderComponents(address offerer,address zone,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 conduitKey,uint256 counter)ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)");
	bytes32 constant OFFERITEM_TYPEHASH = keccak256("OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)");
	bytes32 constant CONSIDERATIONITEM_TYPEHASH = keccak256("ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)");

	string constant SEAPORT_NAME = "Seaport";
	string constant SEAPORT_VERSION = "1.1";
	address constant SEAPORT_ADDRESS = 0x1E0049783F008A0085193E00003D00cd54003c71;
	address constant FEE_COLLECTOR = 0x0000a26b00c1F0DF003000390027140000fAa719;
	address constant ZONE = 0x0000000000000000000000000000000000000000;
	bytes32 constant ZONE_HASH = 0x0000000000000000000000000000000000000000000000000000000000000000;
	bytes32 constant CONDUIT_KEY = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;

	address constant BLOCKIES = 0x46bEF163D6C470a4774f9585F3500Ae3b642e751;
	bytes4 constant MAGICVALUE = 0x1626ba7e;

    uint256 public tokenId;
	uint256 public startTime;
	uint256 public paid;

	receive() external payable
	{
		paid++;
	}

	function setTokenId(uint256 _tokenId) external
	{
		tokenId = _tokenId;
		startTime = block.timestamp;
		IERC721(BLOCKIES).setApprovalForAll(SEAPORT_ADDRESS, true);
	}

	function isValidSignature(bytes32 _givenHash, bytes calldata) external view returns (bytes4 _magicValue)
	{
		bytes32 _expectedHash1 = basicOrderHash(address(this), BLOCKIES, tokenId, 0.0001e18, address(0), startTime, startTime + 30 days, 0);
		bytes32 DOMAIN_SEPARATOR = _hash(EIP712Domain({
			name: SEAPORT_NAME,
			version: SEAPORT_VERSION,
			chainId: block.chainid,
			verifyingContract: SEAPORT_ADDRESS
		}));
		bytes32 _expectedHash2 = keccak256(abi.encodePacked(
			"\x19\x01",
			DOMAIN_SEPARATOR,
			_expectedHash1
		));
		//require(_givenHash == _expectedHash1 || _givenHash == _expectedHash2, "invalid hash");
		return MAGICVALUE;
	}

	function basicOrderHash(address _offerer, address _collection, uint256 _tokenId, uint256 _price, address _paymentToken, uint256 _startTime, uint256 _endTime, uint256 _salt) public pure returns (bytes32)
	{
		uint256 _fee = _price * 1000 / 975 - _price;
		OfferItem[] memory offer = new OfferItem[](1);
		offer[0] = OfferItem({
			itemType: 2,
			token: _collection,
			identifierOrCriteria: _tokenId,
			startAmount: 1,
			endAmount: 1
		});
		ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
		consideration[0] = ConsiderationItem({
			itemType: _paymentToken == address(0) ? 0 : 1,
			token: _paymentToken,
			identifierOrCriteria: 0,
			startAmount: _price,
			endAmount: _price,
			recipient: _offerer
		});
		consideration[1] = ConsiderationItem({
			itemType: _paymentToken == address(0) ? 0 : 1,
			token: _paymentToken,
			identifierOrCriteria: 0,
			startAmount: _fee,
			endAmount: _fee,
			recipient: FEE_COLLECTOR
		});
		OrderComponents memory orderComponents = OrderComponents({
			offerer: _offerer,
			zone: ZONE,
			offer: offer,
			consideration: consideration,
			orderType: 2,
			startTime: _startTime,
			endTime: _endTime,
			zoneHash: ZONE_HASH,
			salt: _salt,
			conduitKey: CONDUIT_KEY,
			counter: 0
		});
		return _hash(orderComponents);
	}

	function _hash(EIP712Domain memory _eip712Domain) private pure returns (bytes32)
	{
		return keccak256(abi.encode(
			EIP712DOMAIN_TYPEHASH,
			keccak256(bytes(_eip712Domain.name)),
			keccak256(bytes(_eip712Domain.version)),
			_eip712Domain.chainId,
			_eip712Domain.verifyingContract
		));
	}

	function _hash(OrderComponents memory _orderComponents) private pure returns (bytes32)
	{
		return keccak256(abi.encode(
			ORDERCOMPONENTS_TYPEHASH,
			_orderComponents.offerer,
			_orderComponents.zone,
			_hash(_orderComponents.offer),
			_hash(_orderComponents.consideration),
			uint256(_orderComponents.orderType),
			_orderComponents.startTime,
			_orderComponents.endTime,
			_orderComponents.zoneHash,
			_orderComponents.salt,
			_orderComponents.conduitKey,
			_orderComponents.counter
		));
	}

	function _hash(OfferItem[] memory _offer) private pure returns (bytes32)
	{
		bytes32[] memory _data = new bytes32[](_offer.length);
		for (uint256 _i = 0; _i < _data.length; _i++) {
			_data[_i] = _hash(_offer[_i]);
		}
		return keccak256(abi.encodePacked(_data));
	}

	function _hash(OfferItem memory _offerItem) private pure returns (bytes32)
	{
		return keccak256(abi.encode(
			OFFERITEM_TYPEHASH,
			uint256(_offerItem.itemType),
			_offerItem.token,
			_offerItem.identifierOrCriteria,
			_offerItem.startAmount,
			_offerItem.endAmount
		));
	}

	function _hash(ConsiderationItem[] memory _consideration) private pure returns (bytes32)
	{
		bytes32[] memory _data = new bytes32[](_consideration.length);
		for (uint256 _i = 0; _i < _data.length; _i++) {
			_data[_i] = _hash(_consideration[_i]);
		}
		return keccak256(abi.encodePacked(_data));
	}

	function _hash(ConsiderationItem memory _considerationItem) private pure returns (bytes32)
	{
		return keccak256(abi.encode(
			CONSIDERATIONITEM_TYPEHASH,
			uint256(_considerationItem.itemType),
			_considerationItem.token,
			_considerationItem.identifierOrCriteria,
			_considerationItem.startAmount,
			_considerationItem.endAmount,
			_considerationItem.recipient
		));
	}
}