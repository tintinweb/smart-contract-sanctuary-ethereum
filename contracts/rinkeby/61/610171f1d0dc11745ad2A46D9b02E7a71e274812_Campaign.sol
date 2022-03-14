/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

pragma solidity 0.8.7;

interface IFactory{
    event CampaignCreated(address indexed campaign, uint256 index);
    
    function owner() external  view returns (address);
	function token() external view returns (address);
    
	function recipients(uint256) external view returns(address);
    function allCampaignLength() external view returns(uint256);
    function allRecipientLength() external view returns(uint256);
    function recipientToCampaignLength(address) external view returns(uint256);
    function allCampaigns(uint256) external view returns(address);
    function campaignApproved(address) external view returns(bool);
    function recipientApproved(address) external view returns(bool);
    function campaignToRecipient(address) external view returns(address);
    function recipientToCampaign(address, uint256) external view returns(address);

	function createRecipient(bytes32, bytes32, bytes32) external returns(bool);
    function createCampaign(uint256, uint256, uint256, bytes32, bytes32, bytes memory) external returns (address);
    
	function updateName(bytes32) external returns(bool);
	function updateWa(bytes32) external returns(bool);
	function updateLocation(bytes32) external returns(bool);

	function toggleApproveRecipient(address) external returns(bool);
	function toggleApproveCampaign(address) external returns(bool);
	function setToken(address) external returns(bool);
    function transferOwnership(address) external returns(bool);
}


pragma solidity 0.8.7;

contract Campaign {
	bytes32 public title;
	uint256 public goal;
	uint256 public startDate;
	uint256 public endDate;
	uint256 public pledged;
	bytes32 public desc;
	bytes public pict;
	address public immutable recipient;
	IFactory public factory;
	bool public initialized;
	address[] public donatur;

	struct Detail{
  		uint256 donaturIndex;
		uint256 dateTime;
  		uint256 amount;
        uint256 idr;
		uint256 index;
  	}

	struct Withdrawal{
		uint256 wAt;
		uint256 wAmount;
		uint256 wIdr;
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

	constructor() {
		factory = IFactory(msg.sender);
		recipient = tx.origin;
	}

	function initialize(	
		uint256 _goal,
		uint256 _startDate,
		uint256 _endDate,
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

	function donate(uint256 _amount, uint256 _idr) external isApproved returns (bool){
		require(isProgress(), "Period donate is over");
		require(pledged <= goal, "Donate completed");
		
		TransferHelper.safeTransferFrom(factory.token(), msg.sender, address(this), _amount);
        
		uint256 donaturIndex = setDonatur(msg.sender);
		uint256 dateTime = block.timestamp;
        string memory prefix = "Invoice-";
		string memory invoiceId = string(abi.encodePacked(prefix, uint2str(invoiceLength()+1))); 
		
		invoices.push(invoiceId);
		invoiceToDetail[invoiceId] = Detail(donaturIndex, dateTime, _amount, _idr, invoiceLength()-1);
		donaturToInvoice[msg.sender].push(invoiceId);

		pledged += _amount;

		return true;
	}

	function withdraw(uint256 _amount, uint256 _idr, bytes32 _des) external onlyRecipient isApproved returns(bool){
		require(block.timestamp >= startDate && pledged > 0 && _amount <= pledged, "Not now");

        string memory prefix = "Receipt-";
		string memory withdrawalId = string(abi.encodePacked(prefix, uint2str(receiptLength()+1)));
		receipt.push(withdrawalId);
		receiptToDetail[withdrawalId] = Withdrawal(block.timestamp, _amount, _idr, _des);

		TransferHelper.safeTransfer(factory.token(), msg.sender, _amount);

		return true;

	}

	function setDonatur(address _donatur) private returns(uint256){
		if(donaturToInvoiceLength(_donatur) == 0){
			donatur.push(_donatur);
		}

		return donaturLength() - 1;
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

	function donaturLength() public view returns(uint256){
		return donatur.length;
	}

	function receiptLength() public view returns(uint256){
		return receipt.length;
	}

	function donaturToInvoiceLength(address _donatur) public view returns(uint256){
		return donaturToInvoice[_donatur].length;
	}

	function invoiceLength() public view returns(uint256){
		return invoices.length;
	}

    function isProgress() public view returns(bool){
        return (block.timestamp >= startDate && block.timestamp <= endDate) ? true : false;
    }

}