/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts/GSN/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/v1.5/SeaportEncoder.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

contract SeaportEncoder is Ownable
{
	struct EIP712Domain {
		string name;
		string version;
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
	address constant SEAPORT_ADDRESS = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

	bytes32 public immutable DOMAIN_SEPARATOR;

	uint256[2] public fee = [975, 1000];
	address public feeCollector = 0x0000a26b00c1F0DF003000390027140000fAa719;
	uint8 public orderType = 0;
	address public zone = 0x0000000000000000000000000000000000000000;
	bytes32 public zoneHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
	bytes32 public conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;

	constructor () public
	{
		uint256 _chainId;
		assembly {
			_chainId := chainid()
		}
		DOMAIN_SEPARATOR = _hash(EIP712Domain({
			name: SEAPORT_NAME,
			version: SEAPORT_VERSION,
			chainId: _chainId,
			verifyingContract: SEAPORT_ADDRESS
		}));
	}

	function configure(uint256[2] memory _fee, address _feeCollector, uint8 _orderType, address _zone, bytes32 _zoneHash, bytes32 _conduitKey) external onlyOwner
	{
		fee = _fee;
		feeCollector = _feeCollector;
		orderType = _orderType;
		zone = _zone;
		zoneHash = _zoneHash;
		conduitKey = _conduitKey;
	}

	function hash(address _offerer, address _collection, uint256 _tokenId, uint256 _price, address _paymentToken, uint256 _startTime, uint256 _endTime, uint256 _salt, uint256 _counter) external view returns (bytes32)
	{
		uint256 _fee = _price * fee[1] / fee[0] - _price;
		while ((_price + _fee) * fee[0] / fee[1] < _price) _fee++;
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
			recipient: feeCollector
		});
		OrderComponents memory orderComponents = OrderComponents({
			offerer: _offerer,
			zone: zone,
			offer: offer,
			consideration: consideration,
			orderType: orderType,
			startTime: _startTime,
			endTime: _endTime,
			zoneHash: zoneHash,
			salt: _salt,
			conduitKey: conduitKey,
			counter: _counter
		});
		return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _hash(orderComponents)));
	}

	function _hash(EIP712Domain memory _eip712Domain) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			EIP712DOMAIN_TYPEHASH,
			keccak256(bytes(_eip712Domain.name)),
			keccak256(bytes(_eip712Domain.version)),
			_eip712Domain.chainId,
			_eip712Domain.verifyingContract
		));
	}

	function _hash(OrderComponents memory _orderComponents) internal pure returns (bytes32)
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

	function _hash(OfferItem[] memory _offer) internal pure returns (bytes32)
	{
		bytes32[] memory _data = new bytes32[](_offer.length);
		for (uint256 _i = 0; _i < _data.length; _i++) {
			_data[_i] = _hash(_offer[_i]);
		}
		return keccak256(abi.encodePacked(_data));
	}

	function _hash(OfferItem memory _offerItem) internal pure returns (bytes32)
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

	function _hash(ConsiderationItem[] memory _consideration) internal pure returns (bytes32)
	{
		bytes32[] memory _data = new bytes32[](_consideration.length);
		for (uint256 _i = 0; _i < _data.length; _i++) {
			_data[_i] = _hash(_consideration[_i]);
		}
		return keccak256(abi.encodePacked(_data));
	}

	function _hash(ConsiderationItem memory _considerationItem) internal pure returns (bytes32)
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