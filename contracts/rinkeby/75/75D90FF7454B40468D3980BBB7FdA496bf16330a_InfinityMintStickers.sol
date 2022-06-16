//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

abstract contract Authentication is InfinityMintObject {
	address deployer;

	mapping(address => bool) internal approved;

	constructor() {
		deployer = sender();
		approved[sender()] = true;
	}

	modifier onlyDeployer() {
		if (sender() != deployer) revert();
		_;
	}

	modifier onlyApproved() {
		if (approved[sender()] == false) revert();
		_;
	}

	function togglePrivilages(address addr) public onlyDeployer {
		approved[addr] = !approved[addr];
	}

	function transferOwnership(address addr) public onlyDeployer {
		deployer = addr;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

/**
    Used by the sticker contract + other contract to implemented the interface needed to call functions relating to ERC721 Royalties
 */

abstract contract IInfinityMintRoyalties {
	function withdraw() public virtual;

	//can only be called by InfinityMint sticker contracts that are attached to the tokenId and is used to
	//deposit the royalties from stickers to the main ERC721 contract and is automatically called by
	//the sticker contract
	function depositStickerRoyalty(uint64 tokenId) public payable virtual;
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintWallet.sol";
import "./Authentication.sol";

abstract contract ITokenStickers is Authentication {
	address public currentOwner;
	address public mainController;
	uint64 public currentKazooId;
	uint256 public stickerPrice;
	uint64 public currentRequestId;
	uint64 public currentStickerId;

	InfinityMintWallet ownerWallet;

	mapping(address => bool) acceptedAddress; //list of accepted addresses
	mapping(uint64 => bytes) requests; //requests to add stickers
	mapping(uint64 => bytes) stickers; //accepted stickers

	//events
	event KazooRequestAccepted(
		uint64 stickerId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event KazooRequestDenied(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event KazooRequestWithdrew(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event KazooRequestAdded(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);

	/**
        acceptRequest

        should edmit KazooRequestAccepted if sucessful
     */
	function acceptRequest(uint64 requestId) public virtual;

	/**
        addRequest

        should edmit KazooRequestAdded if sucessful
     */
	function addRequest(bytes memory packed) public payable virtual;

	/**
        withdrawRequest

        should edmit KazooRequestAdded if sucessful
     */
	function withdrawRequest(uint64 requestId) public virtual;

	/**
        denyRequest

        should edmit KazooRequestAdded if sucessful
     */
	function denyRequest(uint64 requestId) public virtual;

	function setStickerPrice(uint256 price) public onlyApproved {
		stickerPrice = price;
	}

	function hasAcceptedStickers(address addr) public view returns (bool) {
		return acceptedAddress[addr];
	}

	/**
    function getRequestedStickers()
        public
        view
        onlyApproved
        returns (bytes[] memory result)
    {
        //count how many stickers we have that are valid
        uint64 count = 0;
        for (uint64 i = 0; i < currentRequestId; i++)
            if (!InfinityMintUtil.isEqual(requests[i], bytes(""))) count++;

        if (count != 0) {
            //ceate new array with the size of count
            result = new bytes[](count);
            count = 0; //reset count
            for (uint64 i = 0; i < currentRequestId; i++)
                if (!InfinityMintUtil.isEqual(requests[i], bytes("")))
                    //do it again
                    result[count++] = requests[i]; //add to result
        }
    }

    //NOTE: this actually does unpack requests, maybe move to mapping?
    function getMyRequestedStickers()
        public
        view
        returns (bytes[] memory result)
    {
        //count how many stickers we have that are valid
        uint64 count = 0;
        for (uint64 i = 0; i < currentRequestId; i++)
            if (
                !InfinityMintUtil.isEqual(requests[i], bytes("")) &&
                isRequestOwner(requests[i], sender())
            ) count++;

        if (count != 0) {
            //ceate new array with the size of count
            result = new bytes[](count);
            count = 0; //reset count
            for (uint64 i = 0; i < currentRequestId; i++)
                if (
                    !InfinityMintUtil.isEqual(requests[i], bytes("")) &&
                    isRequestOwner(requests[i], sender())
                )
                    //do it again
                    result[count++] = requests[i]; //add to result
        }
    }

    function getStickers() public view returns (bytes[] memory result) {
        //count how many stickers we have that are valid
        uint64 count = 0;
        for (uint64 i = 0; i < currentStickerId; i++)
            if (!InfinityMintUtil.isEqual(stickers[i], bytes(""))) count++;

        if (count != 0) {
            //ceate new array with the size of count
            result = new bytes[](count);
            count = 0; //reset count
            for (uint64 i = 0; i < currentStickerId; i++)
                if (!InfinityMintUtil.isEqual(stickers[i], bytes("")))
                    //do it again
                    result[count++] = stickers[i]; //add to result
        }
    }

    */

	/**

        Code to switch from returning a byte array full of stickers to Ids (non broken up) and id based
        get (broken up)
     */

	function getMyRequestedSticker(uint64 stickerRequestId)
		public
		view
		returns (bytes memory result)
	{
		if (
			InfinityMintUtil.isEqual(requests[stickerRequestId], bytes("")) ||
			!isRequestOwner(requests[stickerRequestId], sender())
		) revert();

		return requests[stickerRequestId];
	}

	function getSticker(uint64 stickerId)
		public
		view
		returns (bytes memory result)
	{
		if (InfinityMintUtil.isEqual(stickers[stickerId], bytes(""))) revert();

		return stickers[stickerId];
	}

	function getRequestedSticker(uint64 stickerId)
		public
		view
		onlyApproved
		returns (bytes memory result)
	{
		if (InfinityMintUtil.isEqual(requests[stickerId], bytes(""))) revert();

		return requests[stickerId];
	}

	function getStickers() public view returns (uint64[] memory result) {
		uint64 count = 0;
		for (uint64 i = 0; i < currentStickerId; i++)
			if (!InfinityMintUtil.isEqual(stickers[i], bytes(""))) count++;

		if (count != 0) {
			//ceate new array with the size of count
			result = new uint64[](count);
			count = 0; //reset count
			for (uint64 i = 0; i < currentStickerId; i++)
				if (!InfinityMintUtil.isEqual(stickers[i], bytes("")))
					result[count++] = i;
		}
	}

	function getRequestedStickers()
		public
		view
		onlyApproved
		returns (uint64[] memory result)
	{
		uint64 count = 0;
		for (uint64 i = 0; i < currentRequestId; i++)
			if (!InfinityMintUtil.isEqual(requests[i], bytes(""))) count++;

		if (count != 0) {
			//ceate new array with the size of count
			result = new uint64[](count);
			count = 0; //reset count
			for (uint64 i = 0; i < currentRequestId; i++)
				if (!InfinityMintUtil.isEqual(requests[i], bytes("")))
					result[count++] = i;
		}
	}

	function getMyRequestedStickers()
		public
		view
		returns (uint64[] memory result)
	{
		uint64 count = 0;
		for (uint64 i = 0; i < currentRequestId; i++)
			if (!InfinityMintUtil.isEqual(requests[i], bytes(""))) count++;

		if (count != 0) {
			//ceate new array with the size of count
			result = new uint64[](count);
			count = 0; //reset count
			for (uint64 i = 0; i < currentRequestId; i++)
				if (
					!InfinityMintUtil.isEqual(requests[i], bytes("")) &&
					isRequestOwner(requests[i], sender())
				) result[count++] = i;
		}
	}

	function isSafe(bytes memory _p) internal view returns (bool) {
		//will call exception if it is bad
		(uint64 kazooId, , , ) = InfinityMintUtil.unpackSticker(_p);
		return kazooId == currentKazooId;
	}

	function isRequestOwner(bytes memory _p, address addr)
		internal
		pure
		returns (bool)
	{
		(, address owner, , ) = abi.decode(
			_p,
			(uint256, address, bytes, uint64)
		);
		return owner == addr;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//this is implemented by every contract in our system
import "./InfinityMintUtil.sol";
import "./InfinityMintValues.sol";

abstract contract InfinityMintObject {
	/*
		Isn't a garuntee
	*/
	modifier onlyContract() {
		uint256 size;
		address account = sender();

		assembly {
			size := extcodesize(account)
		}
		if (size > 0) _;
		else revert();
	}

	//does the same as open zepps contract
	function sender() public view virtual returns (address) {
		return msg.sender;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./ITokenStickers.sol";
import "./IInfinityMintRoyalties.sol";

contract InfinityMintStickers is ITokenStickers {
	uint256 executionCount;
	uint256 tokenValue;

	InfinityMintValues valuesController;

	constructor(
		uint64 kazooId,
		address owner,
		address mainContract,
		address payable kazooWalletAddress,
		address valuesContract
	) ITokenStickers() {
		currentOwner = owner;
		currentKazooId = kazooId;
		valuesController = InfinityMintValues(valuesContract);

		stickerPrice = 1 * valuesController.tryGetValue("baseTokenValue");
		mainController = mainContract;
		ownerWallet = InfinityMintWallet(kazooWalletAddress);
		approved[currentOwner] = true;

		transferOwnership(currentOwner);
	}

	//prevents re-entry attack
	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	function setPrice(uint256 tokenPrice) public onlyDeployer {
		stickerPrice = tokenPrice * tokenValue;
	}

	function acceptRequest(uint64 requestId)
		public
		override
		onlyApproved
		onlyOnce
	{
		if (InfinityMintUtil.isEqual(requests[requestId], bytes(""))) revert();

		(
			uint256 price,
			address sender,
			bytes memory packed,
			uint64 savedRequestId
		) = abi.decode(requests[requestId], (uint256, address, bytes, uint64));

		//price is not the current sticker price
		if (price != stickerPrice) revert();

		//not the saved Id
		if (savedRequestId != requestId) revert();

		//delete first to stop re-entry attack
		delete requests[requestId];

		//percentage cut
		uint256 cut = ( price / 100 ) * valuesController.tryGetValue("stickerSplit");


		//deduct the cut from the price but only if it does not completely take the price
		if (price - cut > 0)
			price = price - cut;
			//else set the cut to zero
		else cut = 0;

		//deposit the royalties for this sticker to the main contract
		IInfinityMintRoyalties(mainController).depositStickerRoyalty{
			value: cut
		}(currentKazooId);

		ownerWallet.deposit{ value: price }(); //deposit it
		stickers[currentStickerId] = packed;

		//add this address to the accepted addresses
		acceptedAddress[sender] = true;
		emit KazooRequestAccepted(currentStickerId++, sender, price, packed);
	}

	function addRequest(bytes memory packed) public payable override onlyOnce {
		if (msg.value != stickerPrice) revert();

		//will revert/call execption if the unpack is bad
		if (!isSafe(packed)) revert();
		//add it!
		requests[currentRequestId] = abi.encode(
			msg.value,
			sender(),
			packed,
			currentRequestId
		);

		emit KazooRequestAdded(currentRequestId++, sender(), msg.value, packed); //emit
	}

	function withdrawRequest(uint64 requestId) public override onlyOnce {
		if (InfinityMintUtil.isEqual(requests[requestId], bytes(""))) revert();

		(
			uint256 price,
			address _sender,
			bytes memory packed,
			uint64 savedRequestId
		) = abi.decode(requests[requestId], (uint256, address, bytes, uint64));

		//sender
		if (_sender != sender()) revert();

		//not the saved Id
		if (savedRequestId != requestId) revert();

		//delete first to stop re-entry attack
		delete requests[requestId];
		//transfer
		address payable senderPayable = payable(_sender);
		senderPayable.transfer(price); //transfer back the price to the sender

		emit KazooRequestWithdrew(requestId, _sender, price, packed);
	}

	function denyRequest(uint64 requestId)
		public
		override
		onlyApproved
		onlyOnce
	{
		if (InfinityMintUtil.isEqual(requests[requestId], bytes(""))) revert();

		(uint256 price, address sender, bytes memory packed) = abi.decode(
			requests[requestId],
			(uint256, address, bytes)
		);

		//delete first to stop re-entry attack
		delete requests[requestId];
		address payable senderPayable = payable(sender);
		senderPayable.transfer(price); //transfer back the price to the sender

		emit KazooRequestDenied(requestId, sender, price, packed);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

library InfinityMintUtil {
	function toString(uint256 _i)
		internal
		pure
		returns (string memory _uintAsString)
	{
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	// https://solidity-by-example.org/signature/
	function getRSV(bytes memory signature)
		public
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(signature.length == 65, "invalid length");
		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := byte(0, mload(add(signature, 96)))
		}
	}

	//checks if two strings (or bytes) are equal
	function isEqual(bytes memory s1, bytes memory s2)
		internal
		pure
		returns (bool)
	{
		bytes memory b1 = bytes(s1);
		bytes memory b2 = bytes(s2);
		uint256 l1 = b1.length;
		if (l1 != b2.length) return false;
		for (uint256 i = 0; i < l1; i++) {
			//check each byte
			if (b1[i] != b2[i]) return false;
		}
		return true;
	}

	function unpackSticker(bytes memory sticker)
		internal
		pure
		returns (
			uint64 tokenId,
			string memory checkSum,
			string memory object,
			address owner
		)
	{
		return abi.decode(sticker, (uint64, string, string, address));
	}

	function unpackKazoo(bytes memory preview)
		internal
		pure
		returns (
			uint64 pathId,
			uint64 pathSize,
			uint64 kazooId,
			address owner,
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory data,
			uint64[] memory assets,
			string[] memory names
		)
	{
		return
			abi.decode(
				preview,
				(
					uint64,
					uint64,
					uint64,
					address,
					address,
					address,
					bytes,
					bytes,
					uint64[],
					string[]
				)
			);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

contract InfinityMintValues {
	mapping(string => uint256) private values;
	mapping(string => bool) private booleanValues;
	mapping(string => bool) private registeredValues;

	address deployer;

	constructor() {
		deployer = msg.sender;
	}

	modifier onlyDeployer() {
		if (msg.sender != deployer) revert();
		_;
	}

	function setValue(string memory key, uint256 value) public onlyDeployer {
		values[key] = value;
		registeredValues[key] = true;
	}

	function setupValues(
		string[] memory keys,
		uint256[] memory _values,
		string[] memory booleanKeys,
		bool[] memory _booleanValues
	) public onlyDeployer {
		require(keys.length == _values.length);
		require(booleanKeys.length == _booleanValues.length);
		for (uint256 i = 0; i < keys.length; i++) {
			setValue(keys[i], _values[i]);
		}

		for (uint256 i = 0; i < booleanKeys.length; i++) {
			setBooleanValue(booleanKeys[i], _booleanValues[i]);
		}
	}

	function setBooleanValue(string memory key, bool value)
		public
		onlyDeployer
	{
		booleanValues[key] = value;
		registeredValues[key] = true;
	}

	function isTrue(string memory key) public view returns (bool) {
		return booleanValues[key];
	}

	function getValue(string memory key) public view returns (uint256) {
		if (!registeredValues[key]) revert("Invalid Value");

		return values[key];
	}

	function tryGetValue(string memory key) public view returns (uint256) {
		if (!registeredValues[key]) return 1;

		return values[key];
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";

contract InfinityMintWallet is InfinityMintObject, Authentication {
	address payable public currentOwner;
	uint64 public currentKazooId;
	uint256 private walletValue;
	uint256 private executionCount;

	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	event Deposit(address indexed sender, uint256 amount, uint256 newTotal);
	event Withdraw(address indexed sender, uint256 amount, uint256 newTotal);

	constructor(uint64 kazooId, address owner) Authentication() {
		//this only refers to being allowed to deposit into the wallet
		approved[owner] = true;
		currentKazooId = kazooId;
		transferOwnership(owner);
	}

	function getBalance() public view onlyApproved returns (uint256) {
		return walletValue;
	}

	//allows the contract to receive tokens immediately calling the deposit
	receive() external payable {
		deposit();
	}

	function deposit() public payable onlyOnce {
		if (msg.value <= 0) revert();

		walletValue = walletValue + msg.value;
		emit Deposit(sender(), msg.value, walletValue);
	}

	function withdraw() public onlyOnce {
		if (sender() != currentOwner) revert();

		//to stop re-entry attack
		uint256 balance = walletValue;
		walletValue = 0;
		currentOwner.transfer(balance);
		emit Withdraw(sender(), balance, walletValue);
	}
}