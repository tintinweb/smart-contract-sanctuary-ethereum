/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface ERC20 {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);

	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address account, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	function increaseAllowance(address spender, uint256 amount) external returns (bool success);
	function decreaseAllowance(address spender, uint256 amount) external returns (bool success);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Context {
	constructor () { }

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}
}

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a && c >= b, "SafeMath: addition overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		uint256 c = a - b;
		require(b <= a && c <= a, errorMessage);
		return c;
	}
}

contract Controllable is Context {
	mapping (address => bool) public controllers;
	event ControllerAdded(address indexed _new);
	event ControllerRemoved(address indexed _old);

	constructor () {
		address msgSender = _msgSender();
		controllers[msgSender] = true;
		emit ControllerAdded(msgSender);
	}

	modifier onlyController() {
		require(controllers[_msgSender()], "Controllable: caller is not a controller");
		_;
	}

	function addController(address _address) external onlyController {
		controllers[_address] = true;
		emit ControllerAdded(_address);
	}

	function removeController(address _address) external onlyController {
		delete controllers[_address];
		emit ControllerRemoved(_address);
	}
}

library SafeERC20 {
	function safeTransfer(ERC20 _token, address _to, uint256 _value) internal {
		require(_token.transfer(_to, _value),"STF1 - Safe transfer failed");
	}
}

contract VIDT is ERC20, Controllable {
	using SafeMath for uint256;
	using SafeERC20 for ERC20;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (uint256 => string) private verifiedNFTs;

	struct FileStruct { uint256 index; uint256 nft; }
	mapping(string => FileStruct) private fileHashes;
	string[] private fileIndex;

	string private constant NAME = 'VIDT DAO';
	string private constant SYMBOL = 'VIDT';
	uint8 private constant _decimals = 18;
	uint256 private _totalSupply = 1e27;

	uint256 private _validationPrice = 1 * 10**18;
	uint256 private _validationFee = 1 * 10**18;
	address private _validationWallet;

	address private constant LEGACY_CONTRACT = address(0xfeF4185594457050cC9c23980d301908FE057Bb1);
	address private _nftContract;
	address private _nftdContract;

	event ValidateFile(uint256 indexed index, string indexed data, uint256 indexed nftID);
	event ValidateNFT(string indexed data, uint256 indexed nftID);
	event ListFile(uint256 indexed index, string indexed data, uint256 indexed nft) anonymous;
	event NewPrice(uint256 indexed newPrice);
	event NewFee(uint256 indexed newFee);
	event NewWallet(address indexed newWallet);
	event NewContracts(address indexed new_nftContract, address indexed new_nftdContract);

	constructor() {
		_validationWallet = msg.sender;
		_balances[msg.sender] = _totalSupply;
		fileIndex.push('');
		fileHashes[''].index = 0;
	}

	function decimals() external view virtual override returns (uint8) {
		return _decimals;
	}

	function symbol() external view virtual override returns (string memory) {
		return SYMBOL;
	}

	function name() external view virtual override returns (string memory) {
		return NAME;
	}

	function totalSupply() external view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) external view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function transferToken(address tokenAddress, uint256 tokens) external returns (bool) {
		return ERC20(tokenAddress).transfer(_validationWallet,tokens);
	}

	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external override returns (bool) {
		require((amount == 0) || (_allowances[msg.sender][spender] == 0),"A1- Reset allowance to 0 first");
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TF1 - Transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "DA1 - Decreased allowance below zero"));
		return true;
	}

	function burn(uint256 amount) external {
		_burn(_msgSender(), amount);
	}

	function burnFrom(address account, uint256 amount) external {
		uint256 decreasedAllowance = _allowances[account][_msgSender()].sub(amount, "BF1 - Burn amount exceeds allowance");
		_approve(account, _msgSender(), decreasedAllowance);
		_burn(account, amount);
	}

	function _transfer(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "T1 - Transfer from the zero address");
		require(recipient != address(0), "T3 - Transfer to the zero address");

		_balances[sender] = _balances[sender].sub(amount, "T4 - Transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);

		emit Transfer(sender, recipient, amount);
	}

	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "B1 - Burn from the zero address");

		_balances[account] = _balances[account].sub(amount, "B2 - Burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);

		emit Transfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "A1 - Approve from the zero address");
		require(spender != address(0), "A2 - Approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
		bytes32 out;
		for (uint i = 0; i < 32; i++) {
			out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
		}
		return out;
	}

	function validateFile(uint256 Payment, bytes calldata Data, bool cStore, bool eLog, bool NFT) external payable returns (bool) {
		require(Payment >= _validationPrice || msg.value >= _validationFee,"V1 - Insufficient payment provided");
		require(Data.length == 64,"V3 - Invalid hash provided");

		uint256 index;
		string calldata fileHash = string(Data);

		if (cStore) {
			if (fileIndex.length > 0) {
				require(fileHashes[fileHash].index == 0,"V4 - This hash was previously validated");
			}

			fileIndex.push(fileHash);
			fileHashes[fileHash].index = fileIndex.length-1;
			index = fileHashes[fileHash].index;
		}

		bool nft_created = false;
		uint256 nftID;

		if (NFT) {
			bytes memory nft_data = "";
			require(fileHashes[fileHash].nft == 0,"V5 - NFT exists already");
			(nft_created, nft_data) = _nftContract.delegatecall(abi.encodeWithSignature("createNFT(bytes)", Data));
			require(nft_created,"V6 - NFT contract call failed");

			nftID = uint256(bytesToBytes32(nft_data,0));

			require(nftID > 0 && bytes(verifiedNFTs[nftID]).length == 0,"V7 - Not a valid NFT ID");

			verifiedNFTs[nftID] = fileHash;
			fileHashes[fileHash].nft = nftID;

			emit ValidateNFT(fileHash,nftID);
		}

		if (_allowances[_validationWallet][msg.sender] >= Payment) {
			_allowances[_validationWallet][msg.sender] = _allowances[_validationWallet][msg.sender].sub(Payment);
		} else {
			_balances[msg.sender] = _balances[msg.sender].sub(Payment);
			_balances[_validationWallet] = _balances[_validationWallet].add(Payment);
		}

		if (eLog) {
			emit ValidateFile(index,fileHash,nftID);
		}

		emit Transfer(msg.sender, _validationWallet, Payment);
		return true;
	}

	function memoryValidateFile(uint256 Payment, bytes calldata Data) external payable returns (bool) {
		require(Payment >= _validationPrice || msg.value >= _validationFee,"V1 - Insufficient payment provided");
		require(Data.length == 64,"V3 - Invalid hash provided");

		uint256 index;
		string calldata fileHash = string(Data);

		if (fileIndex.length > 0) {
			require(fileHashes[fileHash].index == 0,"V4 - This hash was previously validated");
		}

		fileIndex.push(fileHash);
		fileHashes[fileHash].index = fileIndex.length-1;
		index = fileHashes[fileHash].index;

		if (_allowances[_validationWallet][msg.sender] >= Payment) {
			_allowances[_validationWallet][msg.sender] = _allowances[_validationWallet][msg.sender].sub(Payment);
		} else {
			_balances[msg.sender] = _balances[msg.sender].sub(Payment);
			_balances[_validationWallet] = _balances[_validationWallet].add(Payment);
		}

		emit Transfer(msg.sender, _validationWallet, Payment);
		return true;
	}

	function validateNFT(uint256 Payment, bytes calldata Data, bool divisable) external payable returns (bool) {
		require(Payment >= _validationPrice || msg.value >= _validationFee,"V1 - Insufficient payment provided");
		require(Data.length == 64,"V3 - Invalid hash provided");

		string calldata fileHash = string(Data);
		bool nft_created = false;
		uint256 nftID;
		bytes memory nft_data = "";

		require(fileHashes[fileHash].nft == 0,"V5 - NFT exists already");

		if (divisable) {
			(nft_created, nft_data) = _nftdContract.delegatecall(abi.encodeWithSignature("createNFT(bytes)", Data));
		} else {
			(nft_created, nft_data) = _nftContract.delegatecall(abi.encodeWithSignature("createNFT(bytes)", Data));
		}
		require(nft_created,"V6 - NFT contract call failed");

		nftID = uint256(bytesToBytes32(nft_data,0));

		require(nftID > 0 && bytes(verifiedNFTs[nftID]).length == 0,"V7 - Not a valid NFT ID");

		verifiedNFTs[nftID] = fileHash;
		fileHashes[fileHash].nft = nftID;

		if (_allowances[_validationWallet][msg.sender] >= Payment) {
			_allowances[_validationWallet][msg.sender] = _allowances[_validationWallet][msg.sender].sub(Payment);
		} else {
			_balances[msg.sender] = _balances[msg.sender].sub(Payment);
			_balances[_validationWallet] = _balances[_validationWallet].add(Payment);
		}

		emit Transfer(msg.sender, _validationWallet, Payment);
		emit ValidateNFT(fileHash,nftID);
		return true;
	}

	function simpleValidateFile(bytes calldata Data) external returns (string calldata) {
		require(Data.length == 64,"V3 - Invalid hash provided");
		string calldata fileHash = string(Data);

		_balances[msg.sender] = _balances[msg.sender].sub(_validationPrice);
		_balances[_validationWallet] = _balances[_validationWallet].add(_validationPrice);

		emit Transfer(msg.sender, _validationWallet, _validationFee);
		return fileHash;
	}

	function verifyFile(string memory fileHash) external view returns (bool verified) {
		verified = true;
		if (fileIndex.length == 1) {
			verified = false;
		}
		bytes memory a = bytes(fileIndex[fileHashes[fileHash].index]);
		bytes memory b = bytes(fileHash);
		if (a.length != b.length) {
			verified = false;
		}
		if (verified) {
		for (uint256 i = 0; i < a.length; i ++) {
			if (a[i] != b[i]) {
				verified = false;
				break;
			}
		} }
		if (!verified) {
			bool heritage_call = false;
			bytes memory heritage_data = "";
			(heritage_call, heritage_data) = LEGACY_CONTRACT.staticcall(abi.encodeWithSignature("verifyFile(string)", fileHash));
			require(heritage_call,"V0 - Legacy contract call failed");
			assembly {verified := mload(add(heritage_data, 32))}
		}
	}

	function verify(string memory fileHash) external view returns (bool) {
		if (fileIndex.length == 1) {
			return false;
		}
		bytes memory a = bytes(fileIndex[fileHashes[fileHash].index]);
		bytes memory b = bytes(fileHash);
		if (a.length != b.length) {
			return false;
		}
		for (uint256 i = 0; i < a.length; i ++) {
			if (a[i] != b[i]) {
				return false;
			}
		}
		return true;
	}

	function verifyFileNFT(string memory fileHash) external view returns (uint256) {
		if (fileIndex.length == 1) {
			return 0;
		}
		bytes memory a = bytes(fileIndex[fileHashes[fileHash].index]);
		bytes memory b = bytes(fileHash);
		if (a.length != b.length) {
			return 0;
		}
		for (uint256 i = 0; i < a.length; i ++) {
			if (a[i] != b[i]) {
				return 0;
			}
		}
		return fileHashes[fileHash].nft;
	}

	function verifyNFT(uint256 nftID) external view returns (string memory hash) {
		hash = verifiedNFTs[nftID];
	}

	function setPrice(uint256 _newPrice) external onlyController {
		_validationPrice = _newPrice;
		emit NewPrice(_newPrice);
	}

	function setFee(uint256 _newFee) external onlyController {
		_validationFee = _newFee;
		emit NewFee(_newFee);
	}

	function setWallet(address _newWallet) external onlyController {
		require(_newWallet != address(0),"SW1 - Cannot set wallet to zero address");
		_validationWallet = _newWallet;
		emit NewWallet(_newWallet);
	}

	function setContracts(address new_nftContract, address new_nftdContract) external onlyController {
		require(new_nftContract != address(0) && new_nftdContract != address(0),"SC1 - Cannot set wallet to zero address");
		_nftContract = new_nftContract;
		_nftdContract = new_nftdContract;
		emit NewContracts(new_nftContract,new_nftdContract);
	}

	function listFiles(uint256 startAt, uint256 stopAt) onlyController public returns (bool) {
		if (fileIndex.length == 1) {
			return false;
		}
		require(startAt <= fileIndex.length-1,"L1 - Please select a valid start");
		if (stopAt > 0) {
			require(stopAt > startAt && stopAt <= fileIndex.length-1,"L2 - Please select a valid stop");
		} else {
			stopAt = fileIndex.length-1;
		}
		for (uint256 i = startAt; i <= stopAt; i++) {
			emit ListFile(i,fileIndex[i],fileHashes[fileIndex[i]].nft);
		}
		return true;
	}

	function withdraw(uint256 amount) external {
		require(address(this).balance >= amount, "W1 - Insufficient balance");
		(bool success, ) = payable(_validationWallet).call{ value: amount }("");
		require(success, "W2 - Unable to send value, recipient may have reverted");
	}

	function validationPrice() external view returns (uint256) {
		return _validationPrice;
	}

	function validationFee() external view returns (uint256) {
		return _validationFee;
	}

	function validationWallet() external view returns (address) {
		return _validationWallet;
	}

	function nftContract() external view returns (address) {
		return _nftContract;
	}

	function nftdContract() external view returns (address) {
		return _nftdContract;
	}
}