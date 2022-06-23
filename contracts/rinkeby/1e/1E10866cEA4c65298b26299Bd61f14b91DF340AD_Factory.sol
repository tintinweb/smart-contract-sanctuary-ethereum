/**
 *Submitted for verification at Etherscan.io on 2022-06-23
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
	function setToken(address) external returns(bool);
    function transferOwnership(address) external returns(bool);
}

pragma solidity ^0.8.7;

contract Campaign {
	bool public initialized;

	IFactory public immutable factory = IFactory(msg.sender);
	address public immutable recipient = tx.origin;

	uint32 public startDate;
	uint32 public endDate;

	uint128 public goal;
	uint128 public pledged;

	address[] public donatur;
	bytes32 public title;
	bytes32 public desc;
	bytes public pict;

	struct Detail{
		uint16 index;
  		uint16 donaturIndex;
		uint32 dateTime;
        uint64 idr;
  		uint128 amount;
  	}

	struct Withdrawal{
		uint32 wAt;
		uint64 wIdr;
		uint128 wAmount;
		bytes32 des;
	}

	string[] public invoices;
	string[] public receipt;
	mapping (string => Detail) public invoiceToDetail;
	mapping (string => Withdrawal) public receiptToDetail;
	mapping(address => string[]) public donaturToInvoice;
	 
	event WithdrawDesc(address indexed campaign, bytes32 des);

	modifier onlyFactory {
		require(msg.sender == address(factory), "Not factory");
		_;
	}

	modifier onlyRecipient {
		require(msg.sender == recipient, "Not recipient");
		_;
	}

	modifier isApproved {
		require(factory.campaignApproved(address(this)), "Not approved");
		_;
	}

	function initialize(	
		uint32 _startDate,
		uint32 _endDate,
		uint128 _goal,
		bytes32 _title,
		bytes32 _desc,
		bytes memory _pict
	) external onlyFactory returns(bool){
		require(!initialized, "Initialized");

		title = _title;
		goal = _goal;
		startDate = _startDate;
		endDate = _endDate;
		desc = _desc;
		pict = _pict;

		initialized = true;

		return true;
	}

	function donate(uint128 _amount, uint64 _idr) external isApproved returns (bool){
		require(isProgress(), "Period donate is over");
		require(pledged <= goal, "Donate completed");
		
		TransferHelper.safeTransferFrom(factory.token(), msg.sender, address(this), _amount);
        
		uint16 donaturIndex = setDonatur(msg.sender);
		uint32 dateTime = uint32(block.timestamp);
        string memory prefix = "Invoice-";
		string memory invoiceId = string(abi.encodePacked(prefix, uint2str(invoiceLength()+1))); 
		
		invoices.push(invoiceId);
		invoiceToDetail[invoiceId] = Detail(invoiceLength()-1, donaturIndex, dateTime, _idr, _amount);
		donaturToInvoice[msg.sender].push(invoiceId);

		pledged += _amount;

		return true;
	}

	function withdraw(uint128 _amount, uint64 _idr, bytes32 _des) external onlyRecipient isApproved returns(bool){
		require(block.timestamp >= startDate && pledged > 0 && _amount <= pledged, "Not now");

        string memory prefix = "Receipt-";
		string memory withdrawalId = string(abi.encodePacked(prefix, uint2str(receiptLength()+1)));
		receipt.push(withdrawalId);
		receiptToDetail[withdrawalId] = Withdrawal(uint32(block.timestamp), _idr, _amount, _des);

		TransferHelper.safeTransfer(factory.token(), msg.sender, _amount);

		return true;

	}

	function setDonatur(address _donatur) private returns(uint16){
		if(donaturToInvoiceLength(_donatur) == 0){
			donatur.push(_donatur);
			return donaturLength() - 1;
		}

		return invoiceToDetail[donaturToInvoice[ _donatur][0]].donaturIndex;
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

	function donaturLength() public view returns(uint16){
		return uint16(donatur.length);
	}

	function receiptLength() public view returns(uint16){
		return uint16(receipt.length);
	}

	function donaturToInvoiceLength(address _donatur) public view returns(uint16){
		return uint16(donaturToInvoice[_donatur].length);
	}

	function invoiceLength() public view returns(uint16){
		return uint16(invoices.length);
	}

    function isProgress() public view returns(bool){
        return (block.timestamp >= startDate && block.timestamp <= endDate) ? true : false;
    }

}

pragma solidity ^0.8.7;

contract Factory is IFactory{
	struct Detail{
		bytes32 name;
		bytes32 wa;
		bytes32 location;
		bool status;
	}

	address public override owner;
	address public override token;  

	address[] public override allCampaigns;
	address[] public override recipients;

	mapping(address => Detail) public getRecipient;
	mapping(address => address) public override campaignToRecipient;
	mapping(address => address[]) public override recipientToCampaign;
	mapping(address => bool) public override campaignDismissed;
	mapping(address => bool) public override campaignApproved;

	modifier onlyOwner{
		require(owner == msg.sender, "Not owner");
		_;
	}

	modifier onlyRecipient{
		require(getRecipient[msg.sender].name != "", "Not existed");
		_;
	}

	constructor(address _token){
		token = _token;
		owner = msg.sender;
	}

	function allCampaignLength() public override view returns(uint256){
		return allCampaigns.length;
	}

    function allRecipientLength() public override view returns(uint256){
		return recipients.length;
	}

	function recipientApproved(address _recipient) external override view returns(bool){
		return getRecipient[_recipient].status;
	}

	function createRecipient(
		bytes32 _name,
		bytes32 _wa,
		bytes32 _location
	) external override returns(bool){
		require(getRecipient[msg.sender].name == "", "Existed");
		
		recipients.push(msg.sender);
		getRecipient[msg.sender] = Detail(_name, _wa, _location, false);
		
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
		require(getRecipient[msg.sender].status, "Not accepted yet");
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

		emit CampaignCreated(campaign, allCampaignLength()-1);
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

	function setToken(address _token) external override onlyOwner returns(bool){
		token = _token;

		return true;
	}

	function transferOwnership(address _newOwner) external override onlyOwner returns(bool){
        require(_newOwner != address(0), "Can't set to address(0)");
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

	function recipientToCampaignLength(address _recipient) public override view returns(uint){
		return recipientToCampaign[_recipient].length;
	}
}