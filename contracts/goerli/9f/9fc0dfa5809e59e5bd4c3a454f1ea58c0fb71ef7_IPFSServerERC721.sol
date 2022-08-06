// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract IPFSServerERC721 is ERC721, ReentrancyGuard {
	uint8 constant private PREMIUM_FACTOR = 10;
	uint8 constant private MAX_RATING = 11;
	uint8 constant private MIN_RATING = 5;
	uint8 constant private OWNER_PERCENT = 70;
	uint64 constant private MINIMUM_FEE = 0.001 ether;
	uint256 private creationBlock;
	uint256 private totalServers;
	mapping(uint256 => uint256) private totalRatings;
	mapping(uint256 => uint256) private totalUsers;
	mapping(address => uint256) private usersToServerIds;

	event Lease(address indexed from, address indexed to, uint256 indexed serverId);

	struct User{
		address addr;
		bytes32 root;
		bool isPremium;
	}

	struct Server{
		string uri;
		address owner;
		uint256 fee;
		uint256 creationBlock;
		uint256 transferBlock;
		uint8 rating;
		mapping(uint256 => User) users;
		mapping(address => uint256) usersToIds;
		mapping(bytes32 => uint256) rates;
	}
	mapping(uint256 => Server) private servers;

	constructor() ERC721("IPFSServer721 Contract", "IPFSS"){
		creationBlock = block.number;
	}

	function mintServer(string calldata uri, uint256 fee) external {
		require(bytes(uri).length > 0,"invalid uri");
		require(fee >= MINIMUM_FEE,"fee below minimum");

		totalServers = totalServers + 1;

		servers[totalServers].uri = uri;
		servers[totalServers].fee = fee;
		servers[totalServers].owner = msg.sender;
		servers[totalServers].creationBlock = block.number;

		_safeMint(msg.sender, totalServers);

		_safeTransfer(msg.sender, msg.sender, totalServers, "");
	}

	function tokenURI(uint256 serverId) public view override returns (string memory) {
		return servers[serverId].uri;
	}

	function safeTransferFrom(address from, address to, uint256 id, bytes memory data) public override(ERC721) {
		servers[id].transferBlock = block.number;
		_safeTransfer(from, to, id, data);
	}

	function safeTransferFrom(address from, address to, uint256 id) public override(ERC721) {
		servers[id].transferBlock = block.number;
		_safeTransfer(from, to, id, "");
	}

	function transferFrom(address from, address to, uint256 id) public override(ERC721) {
		servers[id].transferBlock = block.number;
		_safeTransfer(from, to, id, "");
	}

	function burn(uint256 serverId) external {
		require(ownerOf(serverId) == msg.sender,"caller isn't the owner");

		servers[serverId].uri = "";
		servers[serverId].fee = 0;
		servers[serverId].owner = address(0);
		servers[serverId].rating = 0;
		servers[serverId].transferBlock = block.number;

		_burn(serverId);
	}

	function setServerSettings(uint256 serverId, string calldata uri, uint256 fee) external {
		require(servers[serverId].owner == msg.sender,"user isn't the owner");
		require(bytes(uri).length > 0,"invalid uri");
		require(fee >= MINIMUM_FEE,"fee below minimum");

		servers[serverId].uri = uri;
		servers[serverId].fee = fee;
	}

	function getServerSettings(uint256 serverId, uint256 userId) external view returns (address, uint256, address, bool, uint256, uint64) {
		Server storage server = servers[serverId];
		User storage user = servers[serverId].users[userId];
		return (server.owner, server.fee, user.addr, user.isPremium, totalServers, MINIMUM_FEE);
	}

	function getUserId(uint256 serverId, address userAddress) external view returns (uint256) {
		return servers[serverId].usersToIds[userAddress];
	}

	function getTotalUsers(uint256 serverId) external view returns (uint256) {
		return totalUsers[serverId];
	}

	function getServerId(address userAddress) external view returns (uint256) {
		return usersToServerIds[userAddress];
	}

	function leaseServer(uint256 serverId, bytes32 root) external payable nonReentrant {
		require(servers[serverId].owner != address(0),"invalid owner");
		require(servers[serverId].usersToIds[msg.sender] == 0,"already leased");
		require(msg.value >= servers[serverId].fee,"fee below minimum");

		uint256 value = msg.value;
		(bool sentToOwner,) = servers[serverId].owner.call{value: (value * OWNER_PERCENT) / 100}("");
		if(sentToOwner){
			value = value - ((value * OWNER_PERCENT) / 100);
		}

		uint256 valueSent = value / totalServers;
		uint256 totalServersLength = totalServers + 1;
		for(uint i=1;i<totalServersLength;i++){
			if(servers[i].rating > MIN_RATING){
				(bool sentToOwners,) = servers[i].owner.call{value: valueSent}("");
				if(sentToOwners){
					value = value - valueSent;
				}
			}
		}
		(servers[serverId].owner.call{value: value}(""));

		uint256 _totalUsers = totalUsers[serverId] + 1;

		servers[serverId].users[_totalUsers].root = root;
		servers[serverId].users[_totalUsers].addr = msg.sender;
		servers[serverId].usersToIds[msg.sender] = _totalUsers;

		uint256 oldServerId = usersToServerIds[msg.sender];
		uint256 oldUserId = servers[oldServerId].usersToIds[msg.sender];
		bool isPremium = servers[oldServerId].users[oldUserId].isPremium;

		if(isPremium){
			servers[serverId].users[_totalUsers].isPremium = true;
		}
		else{
			if(msg.value >= servers[serverId].fee * PREMIUM_FACTOR){
				servers[serverId].users[_totalUsers].isPremium = true;
			}
		}

		totalUsers[serverId] = _totalUsers;
		usersToServerIds[msg.sender] = serverId;

		emit Lease(msg.sender, address(this), serverId);
	}

	function setServerRating(uint256 serverId, uint8 rating) external {
		require(servers[serverId].usersToIds[msg.sender] > 0,"user didn't lease the server");
		require(rating < MAX_RATING,"invalid rating");

		bytes32 rateHash = keccak256(abi.encode(msg.sender, serverId));
		require(servers[serverId].rates[rateHash] == 0,"user already rated");

		totalRatings[serverId] = totalRatings[serverId] + 1;

		servers[serverId].rating = uint8((servers[serverId].rating + rating) / totalRatings[serverId]);
		servers[serverId].rates[rateHash] = rating;
	}

	function getServerRating(uint256 serverId, address userAddress) external view returns (uint8, uint256) {
		uint8 rating = servers[serverId].rating;
		bytes32 rateHash = keccak256(abi.encode(userAddress, serverId));
		uint256 userRating = servers[serverId].rates[rateHash];
		return (rating, userRating);
	}

	function setRoot(uint256 serverId, bytes32 root) external {
		uint256 userId = servers[serverId].usersToIds[msg.sender];
		require(userId > 0,"user didn't lease the server");
		servers[serverId].users[userId].root = root;
	}

	function getRoot(uint256 serverId, uint256 userId) external view returns (bytes32) {
		return servers[serverId].users[userId].root;
	}

	function checkProof(uint256 serverId, uint256 userId, bytes32[] calldata proof) external view returns (bool) {
		bytes32 root = servers[serverId].users[userId].root;
		address user = servers[serverId].users[userId].addr;
		bytes32 leaf = keccak256(abi.encodePacked(user));
		return MerkleProof.verify(proof, root, leaf);
	}
}