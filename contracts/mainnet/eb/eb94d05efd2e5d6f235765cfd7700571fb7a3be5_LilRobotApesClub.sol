/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
// Created by petdomaa100

pragma solidity 0.8.11;


library Address {
	function isContract(address _address) internal view returns(bool) {
		return _address.code.length > 0;
	}
}

library Strings {
	function toString(uint256 value) internal pure returns(string memory) {
		if (value == 0) return "0";

		uint256 temp = value;
		uint256 digits;

		while (temp != 0) {
			digits++;
			temp /= 10;
		}

		bytes memory buffer = new bytes(digits);

		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1( uint8( 48 + uint256(value % 10) ) );
			value /= 10;
		}

		return string(buffer);
	}
}


interface IERC165 {
	function supportsInterface(bytes4 interfaceID) external view returns(bool);
}

interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenID);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function balanceOf(address owner) external view returns(uint256 balance);

	function ownerOf(uint256 tokenID) external view returns(address owner);

	function safeTransferFrom(address from, address to, uint256 tokenID) external;

	function transferFrom(address from, address to, uint256 tokenID) external;

	function approve(address to, uint256 tokenID) external;

	function getApproved(uint256 tokenID) external view returns(address operator);

	function setApprovalForAll(address operator, bool _approved) external;

	function isApprovedForAll(address owner, address operator) external view returns(bool);

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes calldata data) external;
}

interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

interface IERC721Metadata is IERC721 {
	function name() external view returns(string memory);

	function symbol() external view returns(string memory);

	function tokenURI(uint256 tokenID) external view returns(string memory);
}

interface IERC721Enumerable is IERC721 {
	function totalSupply() external view returns(uint256);

	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256 tokenId);

	function tokenByIndex(uint256 index) external view returns(uint256);
}


abstract contract Ownable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	modifier onlyOwner() {
		require(owner() == msg.sender, "Ownable: caller is not the owner");
		_;
	}


	constructor() {
		_transferOwnership(msg.sender);
	}


	function owner() public view virtual returns (address) {
		return _owner;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");

		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;

		_owner = newOwner;

		emit OwnershipTransferred(oldOwner, newOwner);
	}
}


abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceID) public view virtual override returns(bool) {
		return interfaceID == type(IERC165).interfaceId;
	}
}

abstract contract ERC721 is ERC165, IERC721, IERC721Metadata {
	using Address for address;
	using Strings for uint256;

	string private _name;
	string private _symbol;

	mapping(uint256 => address) private _owners;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;

	mapping(address => mapping(address => bool)) private _operatorApprovals;


	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}


	function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165, IERC165) returns(bool) {
		return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceID);
	}

	function balanceOf(address owner) public view virtual override returns(uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");

		return _balances[owner];
	}

	function ownerOf(uint256 tokenID) public view virtual override returns(address) {
		address owner = _owners[tokenID];

		require(owner != address(0), "ERC721: owner query for nonexistent token");

		return owner;
	}

	function name() public view virtual override returns(string memory) {
		return _name;
	}

	function symbol() public view virtual override returns(string memory) {
		return _symbol;
	}

	function tokenURI(uint256 tokenID) public view virtual override returns(string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		string memory baseURI = _baseURI();

		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
	}

	function _baseURI() internal view virtual returns(string memory) {
		return "";
	}

	function approve(address to, uint256 tokenID) public virtual override {
		address owner = ERC721.ownerOf(tokenID);
		
		require(to != owner, "ERC721: approval to current owner");

		require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

		_approve(to, tokenID);
	}

	function getApproved(uint256 tokenID) public view virtual override returns(address) {
		require(_exists(tokenID), "ERC721: approved query for nonexistent token");

		return _tokenApprovals[tokenID];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(msg.sender, operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenID) public virtual override {
		require(_isApprovedOrOwner(msg.sender, tokenID), "ERC721: transfer caller is not owner nor approved");

		_transfer(from, to, tokenID);
	}

	function safeTransferFrom(address from, address to, uint256 tokenID) public virtual override {
		safeTransferFrom(from, to, tokenID, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(msg.sender, tokenID), "ERC721: transfer caller is not owner nor approved");

		_safeTransfer(from, to, tokenID, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenID, bytes memory _data) internal virtual {
		_transfer(from, to, tokenID);

		require(_checkOnERC721Received(from, to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	function _exists(uint256 tokenID) internal view virtual returns(bool) {
		return _owners[tokenID] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenID) internal view virtual returns(bool) {
		require(_exists(tokenID), "ERC721: operator query for nonexistent token");

		address owner = ERC721.ownerOf(tokenID);

		return (spender == owner || getApproved(tokenID) == spender || isApprovedForAll(owner, spender));
	}

	function _safeMint(address to, uint256 tokenID) internal virtual {
		_safeMint(to, tokenID, "");
	}

	function _safeMint(address to, uint256 tokenID, bytes memory _data) internal virtual {
		_mint(to, tokenID);
		
		require(_checkOnERC721Received(address(0), to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	function _mint(address to, uint256 tokenID) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenID), "ERC721: token already minted");

		_beforeTokenTransfer(address(0), to, tokenID);

		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(address(0), to, tokenID);

		_afterTokenTransfer(address(0), to, tokenID);
	}

	function _burn(uint256 tokenID) internal virtual {
		address owner = ERC721.ownerOf(tokenID);

		_beforeTokenTransfer(owner, address(0), tokenID);
		_approve(address(0), tokenID);

		_balances[owner] -= 1;
		delete _owners[tokenID];

		emit Transfer(owner, address(0), tokenID);

		_afterTokenTransfer(owner, address(0), tokenID);
	}

	function _transfer(address from, address to, uint256 tokenID) internal virtual {
		require(ERC721.ownerOf(tokenID) == from, "ERC721: transfer from incorrect owner");
		require(to != address(0), "ERC721: transfer to the zero address");

		_beforeTokenTransfer(from, to, tokenID);
		_approve(address(0), tokenID);

		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(from, to, tokenID);

		_afterTokenTransfer(from, to, tokenID);
	}

	function _approve(address to, uint256 tokenID) internal virtual {
		_tokenApprovals[tokenID] = to;

		emit Approval(ERC721.ownerOf(tokenID), to, tokenID);
	}

	function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
		require(owner != operator, "ERC721: approve to caller");

		_operatorApprovals[owner][operator] = approved;

		emit ApprovalForAll(owner, operator, approved);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenID, bytes memory _data) private returns(bool) {
		if (to == address(this)) return true;

		else if (to.isContract()) {
			try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenID, _data) returns(bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) revert("ERC721: transfer to non ERC721Receiver implementer");

				else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		}

		else return true;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenID) internal virtual {}

	function _afterTokenTransfer(address from, address to, uint256 tokenID) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
	mapping(uint256 => uint256) private _ownedTokensIndex;

	uint256[] private _allTokens;

	mapping(uint256 => uint256) private _allTokensIndex;


	function supportsInterface(bytes4 interfaceID) public view virtual override(IERC165, ERC721) returns(bool) {
		return interfaceID == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceID);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns(uint256) {
		require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

		return _ownedTokens[owner][index];
	}

	function totalSupply() public view virtual override returns(uint256) {
		return _allTokens.length;
	}

	function tokenByIndex(uint256 index) public view virtual override returns(uint256) {
		require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");

		return _allTokens[index];
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenID) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenID);

		if (from == address(0)) _addTokenToAllTokensEnumeration(tokenID);

		else if (from != to) _removeTokenFromOwnerEnumeration(from, tokenID);

		if (to == address(0)) _removeTokenFromAllTokensEnumeration(tokenID);

		else if (to != from) _addTokenToOwnerEnumeration(to, tokenID);
	}

	function _addTokenToOwnerEnumeration(address to, uint256 tokenID) private {
		uint256 length = ERC721.balanceOf(to);

		_ownedTokens[to][length] = tokenID;
		_ownedTokensIndex[tokenID] = length;
	}

	function _addTokenToAllTokensEnumeration(uint256 tokenID) private {
		_allTokensIndex[tokenID] = _allTokens.length;
		_allTokens.push(tokenID);
	}

	function _removeTokenFromOwnerEnumeration(address from, uint256 tokenID) private {
		uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
		uint256 tokenIndex = _ownedTokensIndex[tokenID];

		if (tokenIndex != lastTokenIndex) {
			uint256 lastTokenID = _ownedTokens[from][lastTokenIndex];

			_ownedTokens[from][tokenIndex] = lastTokenID;
			_ownedTokensIndex[lastTokenID] = tokenIndex;
		}

		delete _ownedTokensIndex[tokenID];
		delete _ownedTokens[from][lastTokenIndex];
	}

	function _removeTokenFromAllTokensEnumeration(uint256 tokenID) private {
		uint256 lastTokenIndex = _allTokens.length - 1;
		uint256 tokenIndex = _allTokensIndex[tokenID];
		uint256 lastTokenID = _allTokens[lastTokenIndex];

		_allTokens[tokenIndex] = lastTokenID;
		_allTokensIndex[lastTokenID] = tokenIndex;

		delete _allTokensIndex[tokenID];
		_allTokens.pop();
	}
}



contract LilRobotApesClub is ERC721Enumerable, Ownable {


	uint256 public cost;
	uint256 public maxSupply;

	string private baseURI;


	uint256 public interestPeriod = 1 days;
	uint256 public tokenRewardPerPeriod = 10;


	struct Stake {
		uint256 tokenID;
		address stakeholder;
		uint256 timestamp;
		uint256 collectedRewards;
	}

	Stake[] public stakes;

	mapping(address => bool) private claimedFreeMint;
	mapping(address => uint256) private utilityTokens;
    mapping(uint256=>bool) public usedOriginals;
    
    IERC721 MaleContract;


	event NewStake(uint256 indexed tokenID, address indexed stakeholder);
	event StakeWithdraw(uint256 indexed tokenID);


	constructor(string memory _initBaseURI) ERC721("Lil Robot Apes Club", "LRAC") {
		cost = 30;
		maxSupply = 7000;

		setBaseURI(_initBaseURI);
	


MaleContract = IERC721(0xaf847F761e4FC8165f0261808D8ab5aCbb7fD77A);
    }   

    
    function setOriginalBabyAddress(address _address) external onlyOwner{
        MaleContract = IERC721(_address);
    }


    function _useToken(address _from, uint256 _originalTokenId) internal{
        require(!usedOriginals[_originalTokenId], "Token has been already used.");
        require(MaleContract.ownerOf(_originalTokenId) == _from, "Address does not own the token.");
        usedOriginals[_originalTokenId]=true;
    }


 function claimfreeMint(uint256 _originalTokenID1) external{
        /*Tokens get used*/
        _useToken(msg.sender, _originalTokenID1);


       

        /*New mint*/
        _mintNFT(msg.sender, 1);


    }




function _mintNFT(address _to, uint256 _nftCount) private {
    uint256 newSupply = totalSupply() + 1;
        require(newSupply <= maxSupply, "Number of tokens exceeded max supply!");
        require(_nftCount > 0, "Must mint at least one NFT");

        for (uint256 i = 1; i <= _nftCount; i++) {
            _safeMint(_to, newSupply);

        if (newSupply == 1001 || newSupply == 2001 || newSupply == 3001 || newSupply == 4001 || newSupply == 5001 || newSupply == 6001) {
			setNewCost(newSupply);
		}

}

}





	function mint() public payable {
		uint256 newSupply = totalSupply() + 1;

		require(newSupply <= maxSupply, "Number of tokens exceeded max supply!");

		if (msg.sender != owner()) {
			require(getUtilityTokensOfAddress(msg.sender) >= cost, "Not enough utility tokens!");

			utilityTokens[msg.sender] -= cost;
		}


		_safeMint(msg.sender, newSupply);


		if (newSupply == 1001 || newSupply == 2001 || newSupply == 3001 || newSupply == 4001 || newSupply == 5001 || newSupply == 6001) {
			setNewCost(newSupply);
		}
	}



   function gift(uint256 _mintAmount, address destination) public onlyOwner {
	   uint256 newSupply = totalSupply() + 1;
	   require(newSupply <= maxSupply, "Number of tokens exceeded max supply!");
    require(_mintAmount > 0, "need to mint at least 1 NFT");


      _safeMint(destination, _mintAmount);
    
if (newSupply == 1001 || newSupply == 2001 || newSupply == 3001 || newSupply == 4001 || newSupply == 5001 || newSupply == 6001) {
			setNewCost(newSupply);
		}
	}

	

	function oldfunction() public payable {
		uint256 newSupply = totalSupply() + 1;

		require(newSupply <= maxSupply, "Number of tokens exceeded max supply!");

		require(hasFreeMint(msg.sender), "You already used up your free mint!");


		claimedFreeMint[msg.sender] = true;

		_safeMint(msg.sender, newSupply);


		if (newSupply == 1001 || newSupply == 2001 || newSupply == 3001 || newSupply == 4001 || newSupply == 5001 || newSupply == 6001) {
			setNewCost(newSupply);
		}
	}

	function airDrop(address[] calldata addresses, uint8[] calldata amounts) public payable onlyOwner {
		assert(addresses.length > 0 && amounts.length > 0);
		assert(addresses.length == amounts.length);


		uint16 totalAmount;
		uint256 supply = totalSupply();

		for (uint256 i = 0; i < amounts.length; i++) totalAmount += amounts[0];

		require(supply + totalAmount <= maxSupply, "Number of tokens exceeded max supply!");


		for (uint8 i = 0; i < addresses.length; i++) {
			uint8 amount = amounts[i];
			address _address = addresses[i];

			for (uint8 I = 1; I <= amount; I++) {
				_safeMint(_address, supply + i + I);
			}
		}
	}


	function withdraw() public payable onlyOwner {
		(bool success, ) = payable(owner()).call{value: address(this).balance}("");

		require(success, "Ethereum Transaction: transaction reverted");
	}


	function _baseURI() internal view virtual override returns(string memory) {
		return baseURI;
	}

	function tokenURI(uint256 tokenID) public view virtual override returns(string memory) {
		require(_exists(tokenID), "ERC721 Metadata: URI query for nonexistent token!");

		return string( abi.encodePacked(baseURI, Strings.toString(tokenID), ".json") );
	}

	function ownedTokens(address _address) public view returns(uint256[] memory) {
		uint256 ownerTokenCount = balanceOf(_address);
		uint256[] memory tokenIDs = new uint256[](ownerTokenCount);

		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIDs[i] = tokenOfOwnerByIndex(_address, i);
		}

		return tokenIDs;
	}

	function hasFreeMint(address _address) public view returns(bool) {
		return !claimedFreeMint[_address];
	}

	function getUtilityTokensOfAddress(address _address) public view returns(uint256) {
		return utilityTokens[_address];
	}


	function setBaseURI(string memory newBaseURI) public onlyOwner {
		baseURI = newBaseURI;
	}

	function setMaxSupply(uint256 newAmount) public onlyOwner {
		maxSupply = newAmount;
	}

	function setInterestPeriod(uint256 newPeriod) public onlyOwner {
		interestPeriod = newPeriod;
	}

	function setTokenRewardPerPeriod(uint256 newAmount) public onlyOwner {
		tokenRewardPerPeriod = newAmount;
	}

	function setNewCost(uint256 supply) internal {
		if (supply > 0 && supply <= 1000) cost = 30;

		else if (supply > 1000 && supply <= 2000) cost = 60;

		else if (supply > 2000 && supply <= 3000) cost = 120;

		else if (supply > 3000 && supply <= 4000) cost = 240;

		else if (supply > 4000 && supply <= 5000) cost = 400;

		else if (supply > 5000 && supply <= 6000) cost = 600;

		else cost = 800;
	}


	function stakeToken(uint256 tokenID) public {
		require(ownerOf(tokenID) == msg.sender, "ERC721 Stake: caller is not owner");


		Stake memory stake;

		stake.tokenID = tokenID;
		stake.stakeholder = msg.sender;
		stake.timestamp = block.timestamp;
		stake.collectedRewards = 0;

		stakes.push(stake);


		_safeTransfer(msg.sender, address(this), tokenID, "");

		emit NewStake(tokenID, msg.sender);
	}

	function unStakeToken(uint256 tokenID) public {
		(bool isStaked, uint256 stakeIndex) = isTokenStaked(tokenID);

		require(isStaked, "ERC721 Stake: token is not staked");


		Stake memory stake = stakes[stakeIndex];

		require(stake.stakeholder == msg.sender, "ERC721 Stake: caller is not the owner");


		stakes[stakeIndex] = stakes[stakes.length - 1];
		stakes.pop();

		_safeTransfer(address(this), stake.stakeholder, tokenID, "");

		emit StakeWithdraw(tokenID);
	}

	function collectStakingRewards(uint256 tokenID) public {
		(bool isStaked, uint256 stakeIndex) = isTokenStaked(tokenID);

		require(isStaked, "ERC721 Stake: token is not staked");


		Stake memory stake = stakes[stakeIndex];

		require(stake.stakeholder == msg.sender, "ERC721 Stake: caller is not the owner");


		uint256 rewards = calculateStakeRewards(tokenID);

		require(rewards > 0, "ERC721 Stake: no rewards to collect");


		stakes[stakeIndex].collectedRewards += rewards;
		utilityTokens[msg.sender] += rewards;
	}

	function isTokenStaked(uint256 tokenID) public view returns(bool, uint256) {
		bool isStaked = false;
		uint256 index;

		for (uint256 i = 0; i < stakes.length; i++) {
			if (stakes[i].tokenID != tokenID) continue;

			isStaked = true;
			index = i;
		}

		return (isStaked, index);
	}

	function getStakeInfo(uint256 tokenID) public view returns(Stake memory) {
		(bool isStaked, uint256 stakeIndex) = isTokenStaked(tokenID);

		require(isStaked, "ERC721 Stake: token is not staked");


		return stakes[stakeIndex];
	}

	function calculateStakeRewards(uint256 tokenID) public view returns(uint256) {
		Stake memory stake = getStakeInfo(tokenID);

        uint256 stakePeriod = block.timestamp - stake.timestamp;
        uint256 periods = stakePeriod / interestPeriod;
        uint256 rewards = periods * tokenRewardPerPeriod - stake.collectedRewards;

        return rewards;
	}
}