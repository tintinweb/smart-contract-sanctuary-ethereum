/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity ^0.8.7;
interface IFactory{
	event CampaignCreated(address indexed campaign, uint256 index);
	event RecipientCreated(address indexed recipient, uint256 index);
	
	function owner() external  view returns (address);
	function token() external view returns (address);
    
	function recipients(uint256) external view returns(address);
	function allCampaignLength() external view returns(uint256);
	function allRecipientLength() external view returns(uint256);
	function recipientToCampaignLength(address) external view returns(uint256);
	function allCampaigns(uint256) external view returns(address);
	function campaignDismissed(address) external view returns(bool);
	function campaignApproved(address) external view returns(bool);
	function recipientApproved(address) external view returns(bool);
	function campaignToRecipient(address) external view returns(address);
	function recipientToCampaign(address, uint256) external view returns(address);

	function createRecipient(bytes32, bytes32, bytes32) external returns(bool);
	function createCampaign(uint32, uint32, uint128, bytes32, bytes32, bytes memory) external returns (address);

	function updateName(bytes32) external returns(bool);
	function updateWa(bytes32) external returns(bool);
	function updateLocation(bytes32) external returns(bool);

	function toggleApproveRecipient(address) external returns(bool);
	function toggleDismissCampaign(address) external returns(bool);
	function toggleApproveCampaign(address) external returns(bool);
	function transferOwnership(address) external returns(bool);
}


pragma solidity ^0.8.7;

contract Campaign {
	IFactory public immutable factory = IFactory(msg.sender);
	address public immutable recipient = tx.origin;

 	// 1 slot = 256 bit / 32 bytes

	uint128 public goal;
	uint128 public pledged;
	bytes32 public title;
	bytes32 public desc;
	uint128 public startDate;
	uint128 public endDate;
	uint256 private initialized;

	address[] public donatur;
	string[] public invoices;
	string[] public receipt;

	bytes public pict;

	struct Detail{
		uint64 index;
		uint64 donaturIndex;
		uint128 dateTime;
		uint128 idr;
		uint128 amount;
	}

	struct Withdrawal{
		uint256 wAt;
		uint128 wIdr;
		uint128 wAmount;
		bytes32 des;
	}

	mapping(string => Detail) public invoiceToDetail;
	mapping(string => Withdrawal) public receiptToDetail;
	mapping(address => string[]) public donaturToInvoice;
	 
	event WithdrawDesc(address indexed campaign, bytes32 des);

	modifier isApproved {
		require(factory.campaignApproved(address(this)), "!approved");
		_;
	}

	function initialize(
		uint128 _startDate,
		uint128 _endDate,
		uint128 _goal,
		bytes32 _title,
		bytes32 _desc,
		bytes calldata _pict
	) external returns(bool){
		require(msg.sender == address(factory) && initialized == 0, "initialized");

		title = _title;
		goal = _goal;
		startDate = _startDate;
		endDate = _endDate;
		desc = _desc;
		pict = _pict;

		initialized = 1;

		return true;
	}

	function donate(uint128 _amount, uint128 _idr) external isApproved returns (bool){
		uint128 pledgedAmount = pledged;
		require(isProgress() && pledgedAmount <= goal, "bad");
		
		string memory prefix = "Invoice-";
		uint64 invoiceSize = uint64(invoices.length);
		string memory invoiceId = string(abi.encodePacked(prefix, uint2str(invoiceSize + 1))); 
		
		invoices.push(invoiceId);
		invoiceToDetail[invoiceId] = Detail(invoiceSize - 1, setDonatur(msg.sender), uint128(block.timestamp), _idr, _amount);
		donaturToInvoice[msg.sender].push(invoiceId);

		pledged = pledgedAmount + _amount;

		TransferHelper.safeTransferFrom(factory.token(), msg.sender, address(this), _amount);

		return true;
	}

	function withdraw(uint128 _amount, uint128 _idr, bytes32 _des) external isApproved returns(bool){
		uint128 pledgedAmount = pledged;
		require(block.timestamp >= startDate && pledgedAmount > 0 && _amount <= pledgedAmount && msg.sender == recipient, "bad");

		string memory prefix = "Receipt-";
		string memory withdrawalId = string(abi.encodePacked(prefix, uint2str(receipt.length + 1)));

		receipt.push(withdrawalId);
		receiptToDetail[withdrawalId] = Withdrawal(block.timestamp, _idr, _amount, _des);

		TransferHelper.safeTransfer(factory.token(), msg.sender, _amount);

		return true;
	}

	function setDonatur(address _donatur) internal returns(uint64){
		if(donaturToInvoice[_donatur].length == 0){
			donatur.push(_donatur);
			return uint64(donatur.length) - 1;
		}

		return invoiceToDetail[donaturToInvoice[_donatur][0]].donaturIndex;
	}

	function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len;
		while (_i != 0) {
			k = k-1;
			uint8 temp = (48 + uint8(_i - _i / 10 * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function donaturLength() external view returns(uint256){
		return donatur.length;
	}

	function receiptLength() external view returns(uint256){
		return receipt.length;
	}

	function donaturToInvoiceLength(address _donatur) external view returns(uint256){
		return donaturToInvoice[_donatur].length;
	}

	function invoiceLength() external view returns(uint256){
		return invoices.length;
	}

	function isProgress() public view returns(bool){
		uint128 dateTime = uint128(block.timestamp);
		return (dateTime >= startDate && dateTime <= endDate) ? true : false;
	}
}


pragma solidity ^0.8.7;
// solidity punya 3 penyimpanan => storage, memory/calldata, stack
contract Factory is IFactory{
	address public immutable override token; // 20 bytes
	
	struct Detail{
		bytes32 name;
		bytes32 wa;
		bytes32 location;
		// bool status; // bool = 8bit
		bool status; // 0 = false || 1 = true
	}

	address public override owner; // 20 bytes => slot 0

	address[] public override allCampaigns; // dynamic size length variable => slot 1
	// slot 1 = length array (uint256)
	// allCampaigns[0] => keccak256(1) + 0
	// allCampaigns[1] => keccak256(1) + 1
	// dst => web3.eth.getStorageAt(slot?) => number/hex

	address[] public override recipients; // => slot2 [web3.eth.getStorageAt(slot)]
	// slot 2 = length array (uint256)
	// recipients[0] => keccak256(slot2) + 0
	// recipients[1] => keccak256(slot2) + 1
	// dst => web3.eth.getStorageAt(keccak256(slot?) + n) => number/hex

	mapping(address => Detail) public getRecipient; // => slot3
	// slot 3 = empty
	// getRecipient[0xabc..] => keccak256(0xabc, Struct) ??
	mapping(address => address) public override campaignToRecipient;
	mapping(address => address[]) public override recipientToCampaign;
	mapping(address => bool) public override campaignDismissed;
	mapping(address => bool) public override campaignApproved;

	modifier onlyOwner{
		require(owner == msg.sender, "!owner");
		_;
	}

	modifier onlyRecipient{
		require(getRecipient[msg.sender].name != "", "!found");
		_;
	}

	constructor(address _token){
		token = _token;
		owner = msg.sender;
	}

	function allCampaignLength() external override view returns(uint256){
		return allCampaigns.length;
	}

	function allRecipientLength() external override view returns(uint256){
		return recipients.length;
	}

	function recipientApproved(address _recipient) external override view returns(bool){
		return (getRecipient[_recipient].status);
	}

	function createRecipient(
		bytes32 _name,
		bytes32 _wa,
		bytes32 _location
	) external override returns(bool){
		// 1st time storage call = 2100 gas
		// next call = 100
		// baris 74 call getRecipient[msg.sender].name => gas 2100
		// baris 80 call getRecipient[msg.sender].name => gas 100
		// total = 2200 gas

		// solusi
		// create memory variable, set storage variable inside
		// bytes32 recipientName = getRecipient[msg.sender].name (baris 74) => mstore + sload = 3 + 2100 = 2103
		// baris 75 call recipientName (mload) = 3
		// baris 81 call recipientName (mload) = 3
		// total = 2109 gas

		require(getRecipient[msg.sender].name == "", "existed");
		
		recipients.push(msg.sender);
		// getRecipient[msg.sender] = Detail(_name, _wa, _location, false);
		getRecipient[msg.sender] = Detail(_name, _wa, _location, false);
		emit RecipientCreated(msg.sender, recipients.length - 1);
		return true;
	}

	function createCampaign(
		uint32 _startDate,
		uint32 _endDate,
		uint128 _goal,
		bytes32 _title,
		bytes32 _desc,
		bytes memory _pict
	) external override onlyRecipient returns(address campaign){
		require(getRecipient[msg.sender].status, "bad");
		campaign = address(new Campaign());

		allCampaigns.push(campaign);
		campaignToRecipient[campaign] = msg.sender;
		recipientToCampaign[msg.sender].push(campaign);

		Campaign(campaign).initialize(
			_startDate,
			_endDate,
			_goal,
			_title,
			_desc,
			_pict
		);

		emit CampaignCreated(campaign, allCampaigns.length - 1);
	}

	function toggleApproveRecipient(address _recipient) external override onlyOwner returns(bool){
		getRecipient[_recipient].status = !getRecipient[_recipient].status; 
		
		return true;
	}

	function toggleApproveCampaign(address _campaign) external override onlyOwner returns(bool){
		campaignApproved[_campaign] = !campaignApproved[_campaign];
		
		return true;
	}

	function toggleDismissCampaign(address _campaign) external override onlyOwner returns(bool){
		campaignDismissed[_campaign] = !campaignDismissed[_campaign]; 
		
		return true;
	}

	function transferOwnership(address _newOwner) external override onlyOwner returns(bool){
			require(_newOwner != address(0), "bad");
			owner = _newOwner;

			return true;
    }

	function updateName(bytes32 _name) external override onlyRecipient returns(bool){
		getRecipient[msg.sender].name = _name;

		return true;
	}

	function updateWa(bytes32 _wa) external override onlyRecipient returns(bool){
		getRecipient[msg.sender].wa = _wa;

		return true;
	}

	function updateLocation(bytes32 _location) external override onlyRecipient returns(bool){
		getRecipient[msg.sender].location = _location;

		return true;
	}

	function recipientToCampaignLength(address _recipient) external override view returns(uint){
		return recipientToCampaign[_recipient].length;
	}
}