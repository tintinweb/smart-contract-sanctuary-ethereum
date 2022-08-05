// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";

contract MailERC721 is ERC721, ReentrancyGuard {
	uint8 constant private NO_STATUS = 0;
	uint8 constant private ALLOWED = 1;
	uint8 constant private BLOCKED = 2;
	uint256 private creationBlock;
	uint256 private mailBoxId;
	uint256 private mailId;
	mapping(uint256 => address) private mailBoxIdToAddress;
	mapping(bytes32 => uint8) private whitelistAddresses;
	mapping(bytes32 => bool) private freeMails;

	struct MailBox{
		uint256 id;
		string uri;
		uint256 fee;
		uint256 creationBlock;
		uint256 totalEmails;
		bool isPaid;
		mapping(bytes32 => uint256) sentTo;
		mapping(address => uint256) totalSentTo;
		mapping(uint256 => Mail) mail;
	}
	mapping(address => MailBox) private mailbox;

	struct Mail{
		uint256 id;
		string uri;
		uint256 creationBlock;
		uint256 transferBlock;
	}

	constructor() ERC721("Mail", "MAIL"){
		creationBlock = block.number;
	}

	function _mintMailBox(string memory uri) private {
		require(bytes(uri).length > 0,"invalid mailbox uri");
		require(mailbox[msg.sender].id == 0,"can't create mailbox");

		mailBoxId = mailBoxId + 1;
		mailBoxIdToAddress[mailBoxId] = msg.sender;

		mailbox[msg.sender].id = mailBoxId;
		mailbox[msg.sender].uri = uri;
		mailbox[msg.sender].creationBlock = block.number;
	}

	function _mintMail(string memory uri) private {
		require(bytes(uri).length > 0,"invalid mail uri");
		require(mailbox[msg.sender].id > 0,"sender hasn't mailbox");

		mailId = mailId + 1;

		uint256 totalEmails = mailbox[msg.sender].totalEmails + 1;
		mailbox[msg.sender].mail[totalEmails].id = mailId;
		mailbox[msg.sender].mail[totalEmails].uri = uri;
		mailbox[msg.sender].mail[totalEmails].creationBlock = block.number;
		mailbox[msg.sender].totalEmails = totalEmails;

		_safeMint(msg.sender, mailId);
	}

	function tokenURI(uint256 _mailBoxId) public view override returns (string memory) {
		address userAddress = mailBoxIdToAddress[_mailBoxId];
		return mailbox[userAddress].uri;
	}

	function getMail(address userAddress, uint256 id) external view returns (string memory) {
		return mailbox[userAddress].mail[id].uri;
	}

	function sendMail(address to, string memory mailUri) external payable nonReentrant {
		_mintMail(mailUri);

		_antiSPAM(to);

		_updateTotalsAndSend(to, mailUri);
	}

	function sendMail(address to, string memory mailBoxUri, string memory mailUri) external payable nonReentrant {
		_mintMailBox(mailBoxUri);

		_mintMail(mailUri);

		_antiSPAM(to);

		_updateTotalsAndSend(to, mailUri);
	}

	function _antiSPAM(address to) private {
		//require(mailbox[to].id > 0,"receiver hasn't mailbox");

		bytes32 fromToHash = keccak256(abi.encode(msg.sender, to));
		require(whitelistAddresses[fromToHash] < BLOCKED,"address blocked by the user");

		if((mailbox[to].isPaid && !freeMails[fromToHash]) ||
			(mailbox[msg.sender].totalSentTo[to] == 0 && mailbox[to].totalSentTo[msg.sender] == 0)){
			require(msg.value >= mailbox[to].fee,"fee below minimum");

			(bool sentEther,) = to.call{value: msg.value}("");
			require(sentEther, "failed to send ether");

			whitelistAddresses[fromToHash] = ALLOWED;
		}
	}

	function _updateTotalsAndSend(address to, string memory uri) private {
		uint256 totalEmails = mailbox[msg.sender].totalEmails;
		mailbox[msg.sender].mail[totalEmails].transferBlock = block.number;

		uint256 totalSentTo = mailbox[msg.sender].totalSentTo[to] + 1;
		mailbox[msg.sender].totalSentTo[to] = totalSentTo;

		bytes32 toIdHash = keccak256(abi.encode(to, totalSentTo));
		mailbox[msg.sender].sentTo[toIdHash] = totalEmails;

		uint256 id = mailbox[msg.sender].mail[totalEmails].id;
		_safeTransfer(msg.sender, to, id, "");

		totalEmails = mailbox[to].totalEmails + 1;
		mailbox[to].mail[totalEmails].id = id;
		mailbox[to].mail[totalEmails].uri = uri;
		mailbox[to].mail[totalEmails].transferBlock = block.number;
		mailbox[to].totalEmails = totalEmails;
	}

	function safeTransferFrom(address, address, uint256, bytes memory) public pure override(ERC721) {
		require(false,"can't use this function");
	}

	function safeTransferFrom(address, address, uint256) public pure override(ERC721) {
		require(false,"can't use this function");
	}

	function transferFrom(address, address, uint256) public pure override(ERC721) {
		require(false,"can't use this function");
	}

	function burnMailBox() external {
		require(mailbox[msg.sender].id > 0,"sender hasn't mailbox");

		mailbox[msg.sender].id = 0;
		mailbox[msg.sender].uri = "";
		mailbox[msg.sender].fee = 0;
		mailbox[msg.sender].isPaid = false;

		uint256 totalMails = mailbox[msg.sender].totalEmails + 1;
		for(uint i=1;i<totalMails;i++){
			uint256 id = mailbox[msg.sender].mail[i].id;
			burnMail(id);
		}

		mailbox[msg.sender].totalEmails = 0;
	}

	function burnMail(uint256 id) public {
		if(_exists(id) && ownerOf(id) == msg.sender){
			mailbox[msg.sender].mail[id].uri = "";
			mailbox[msg.sender].mail[id].transferBlock = block.number;

			_burn(id);
		}
	}

	function getMailBoxInfo(address userAddress) external view returns (uint256, string memory, uint256, uint256, uint256, bool, uint256) {
		MailBox storage _mailbox = mailbox[userAddress];
		return (_mailbox.id, _mailbox.uri, creationBlock, _mailbox.creationBlock, _mailbox.fee, _mailbox.isPaid, mailBoxId);
	}

	function getMailInfo(address userAddress, uint256 id) external view returns (uint256, string memory, uint256, uint256, uint256) {
		Mail storage mail = mailbox[userAddress].mail[id];
		return (mailbox[userAddress].totalEmails, mail.uri, mail.creationBlock, mail.transferBlock, mailId);
	}

	function filterMail(address from, address to, uint256 id) external view returns (uint256, uint256) {
		uint256 totalSentTo = mailbox[from].totalSentTo[to];

		bytes32 toIdHash = keccak256(abi.encode(to, id));
		uint256 _id = mailbox[from].sentTo[toIdHash];

		return (totalSentTo, _id);
	}

	function setFee(uint256 fee) external {
		mailbox[msg.sender].fee = fee;
	}

	function setIsPaid(bool isPaid) external {
		mailbox[msg.sender].isPaid = isPaid;
	}

	function setFreeMail(address from, bool free) external {
		bytes32 fromToHash = keccak256(abi.encode(from, msg.sender));
		freeMails[fromToHash] = free;
	}

	function isFreeMail(address from, address to) external view returns (bool) {
		bytes32 fromToHash = keccak256(abi.encode(from, to));
		return freeMails[fromToHash];
	}

	function setWhiteListAddress(address from, bool value) external {
		bytes32 fromToHash = keccak256(abi.encode(from, msg.sender));
		whitelistAddresses[fromToHash] = value ? ALLOWED : BLOCKED;
	}

	function getWhiteListAddress(address from, address to) external view returns (bool) {
		bytes32 fromToHash = keccak256(abi.encode(from, to));
		return whitelistAddresses[fromToHash] < BLOCKED;
	}
}