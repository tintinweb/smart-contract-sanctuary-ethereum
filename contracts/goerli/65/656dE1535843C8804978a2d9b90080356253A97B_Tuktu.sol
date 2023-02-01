// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

uint8 constant UNILEVEL = 1; // Unilevel matrix (Sun, unlimited leg)
uint8 constant BINARY = 2; // Binary marix - Tow leg
uint8 constant TERNARY = 3; // Ternary matrix - Three leg

library Algorithms {
	// Factorial x! - Use recursion
	function Factorial(uint256 _x) internal pure returns (uint256 _r) {
		if (_x == 0) return 1;
		else return _x * Factorial(_x - 1);
	}

	// Exponentiation x^y - Algorithm: "exponentiation by squaring".
	function Exponential(uint256 _x, uint256 _y) internal pure returns (uint256 _r) {
		// Calculate the first iteration of the loop in advance.
		uint256 result = _y & 1 > 0 ? _x : 1;
		// Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
		for (_y >>= 1; _y > 0; _y >>= 1) {
			_x = MulDiv18(_x, _x);
			// Equivalent to "y % 2 == 1" but faster.
			if (_y & 1 > 0) {
				result = MulDiv18(result, _x);
			}
		}
		_r = result;
	}

	// https://github.com/paulrberg/prb-math
	// @notice Emitted when the ending result in the fixed-point version of `mulDiv` would overflow uint256.
	error MulDiv18Overflow(uint256 x, uint256 y);

	function MulDiv18(uint256 x, uint256 y) internal pure returns (uint256 result) {
		// How many trailing decimals can be represented.
		uint256 UNIT = 1e18;
		// Largest power of two that is a divisor of `UNIT`.
		uint256 UNIT_LPOTD = 262144;
		// The `UNIT` number inverted mod 2^256.
		uint256 UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

		uint256 prod0;
		uint256 prod1;

		assembly {
			let mm := mulmod(x, y, not(0))
			prod0 := mul(x, y)
			prod1 := sub(sub(mm, prod0), lt(mm, prod0))
		}
		if (prod1 >= UNIT) {
			revert MulDiv18Overflow(x, y);
		}
		uint256 remainder;
		assembly {
			remainder := mulmod(x, y, UNIT)
		}
		if (prod1 == 0) {
			unchecked {
				return prod0 / UNIT;
			}
		}
		assembly {
			result := mul(
				or(
					div(sub(prod0, remainder), UNIT_LPOTD),
					mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
				),
				UNIT_INVERSE
			)
		}
	}
}

library AffiliateCreator {
	// https://stackoverflow.com/questions/67893318/solidity-how-to-represent-bytes32-as-string
	function ToHex16(bytes16 data) internal pure returns (bytes32 result) {
		result =
			(bytes32(data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
			((bytes32(data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64);
		result =
			(result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
			((result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32);
		result =
			(result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
			((result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16);
		result =
			(result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
			((result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8);
		result =
			((result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4) |
			((result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8);
		result = bytes32(
			0x3030303030303030303030303030303030303030303030303030303030303030 +
				uint256(result) +
				(((uint256(result) + 0x0606060606060606060606060606060606060606060606060606060606060606) >> 4) &
					0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
				7
		);
	}

	function ToHex(bytes32 data) internal pure returns (string memory) {
		return string(abi.encodePacked('0x', ToHex16(bytes16(data)), ToHex16(bytes16(data << 128))));
	}

	function Create(bytes32 _Bytes32, uint8 _len) internal pure returns (bytes16 _r) {
		string memory s = ToHex(_Bytes32);
		bytes memory b = bytes(s);
		bytes memory r = new bytes(_len);
		for (uint i = 0; i < _len; ++i) r[i] = b[i + 3];
		return bytes16(bytes(r));
	}

	function Create(uint8 _len) internal view returns (bytes16 _r) {
		return
			Create(
				bytes32(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, block.number * _len))),
				_len
			);
	}
}

library Address {
	function isContract(address account) internal view returns (bool) {
		return account.code.length > 0;
	}
}

library Uint32Array {
	function RemoveValue(uint32[] storage _Array, uint32 _Value) internal {
		require(_Array.length > 0, "Uint32: Can't remove from empty array");
		// Move the last element into the place to delete
		for (uint32 i = 0; i < _Array.length; ++i) {
			if (_Array[i] == _Value) {
				_Array[i] = _Array[_Array.length - 1];
				break;
			}
		}
		_Array.pop();
	}

	function RemoveIndex(uint32[] storage _Array, uint64 _Index) internal {
		require(_Array.length > 0, "Uint32: Can't remove from empty array");
		require(_Array.length > _Index, 'Index out of range');
		// Move the last element into the place to delete
		_Array[_Index] = _Array[_Array.length - 1];
		_Array.pop();
	}

	function AddNoDuplicate(uint32[] storage _Array, uint32 _Value) internal {
		for (uint32 i = 0; i < _Array.length; ++i) if (_Array[i] == _Value) return;
		_Array.push(_Value);
	}

	function TrimRight(uint32[] memory _Array) internal pure returns (uint32[] memory _Return) {
		require(_Array.length > 0, "Uint32: Can't trim from empty array");
		uint32 count;
		for (uint32 i = 0; i < _Array.length; ++i) {
			if (_Array[i] != 0) count++;
			else break;
		}

		_Return = new uint32[](count);
		for (uint32 j = 0; j < count; ++j) {
			_Return[j] = _Array[j];
		}
	}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import './TMatrix.sol';
import './XProgram.sol';
import './TBalance.sol';
import './Library.sol';

abstract contract TAccount is XProgram {
	using Address for address;
	using AffiliateCreator for bytes32;
	using Uint32Array for uint32[];

	struct Account {
		uint32 AccountID;
		bytes16 Affiliate; // User can modify and Using like AccountID
		address Address; // One address can have multiple accounts
		uint32 RegTime; // Registration datetime
		bool Stoped; // User can stop account and withdraw all
	}

	uint32 private numAccount; // Total account number
	mapping(uint32 => Account) private Accounts; // Account info of AccountID
	mapping(address => uint32[]) private AccountsOf; // AccountIDs of address
	mapping(bytes16 => uint32) private Affiliates; // Affiliate to AccountID

	event Registration(uint256 _RT, uint32 indexed _AID, uint32 _SID, uint32 _UB, uint32 _UT);

	constructor(uint32 _Starting) TMatrix(_Starting) XProgram(_Starting) {
		InitializeAccount(_Starting);
	}

	function InitializeAccount(uint32 _Starting) private {
		Accounts[_Starting] = Account({
			AccountID: _Starting,
			Affiliate: bytes16(0),
			Address: msg.sender,
			RegTime: uint32(block.timestamp),
			Stoped: false
		});
		AccountsOf[msg.sender].push(_Starting);
	}

	function _register(
		address _Address,
		uint32 _SID,
		uint32 _UB,
		uint32 _UT,
		uint8 _LO // Level On
	) internal {
		require(_Address.isContract() == false, 'Registration: can not contract');

		uint32 newid = _AccountIDCreator();
		// Init new account
		Accounts[newid] = Account({
			AccountID: newid,
			Affiliate: bytes16(0),
			Address: _Address,
			RegTime: uint32(block.timestamp),
			Stoped: false
		});
		AccountsOf[_Address].push(newid);

		_InitAccountForMaxtrixes(newid, _SID, _UB, _UT); // Initialize for Matrixes
		// _InitAccountForXProgram(newid, _LO); // Initialization and Activation for each xprogram

		emit Registration(block.timestamp, newid, _SID, _UB, _UT);
	}

	function _AccountIDCreator() internal returns (uint32 _NewAccountID) {
		while (true) {
			unchecked {
				++numAccount;
				if (Accounts[numAccount].AccountID == 0) return numAccount;
			}
		}
	}

	function _AffiliateCreator() internal view returns (bytes16 _Affiliate) {
		while (true) {
			_Affiliate = AffiliateCreator.Create(8);
			if (Affiliates[_Affiliate] == 0) return _Affiliate;
		}
	}

	function _UpdateAffiliate(uint32 _AID, bytes16 _NewAffiliate) internal {
		Affiliates[Accounts[_AID].Affiliate] = 0;
		Affiliates[_NewAffiliate] = _AID;
		Accounts[_AID].Affiliate = _NewAffiliate;
	}

	function _AccountOfAffiliate(bytes16 _Affiliate) internal view returns (uint32 _AID) {
		return _AID = Affiliates[_Affiliate];
	}

	function _AffiliateOfAccount(uint32 _AID) internal view returns (bytes16 _Affiliate) {
		return _Affiliate = Accounts[_AID].Affiliate;
	}

	function _AddressOfAccount(uint32 _AID) internal view returns (address _Address) {
		return Accounts[_AID].Address;
	}

	function _UpdateAddress(uint32 _AID, address _Address) internal {
		Accounts[_AID].Address = _Address;
		AccountsOf[msg.sender].RemoveValue(_AID);
		AccountsOf[_Address].AddNoDuplicate(_AID);
	}

	function _AccountsOf(address _address) internal view returns (uint32[] memory _AccountIDs) {
		return AccountsOf[_address];
	}

	// Return a account id LATEST/NEWEST of Address
	function _GetLatestAccountsOf(address _address) internal view returns (uint32 _AID) {
		uint32[] memory accounts = AccountsOf[_address];
		if (accounts.length > 0) {
			_AID = accounts[0];
			for (uint32 i = 1; i < accounts.length; ++i)
				if (Accounts[accounts[i]].RegTime > Accounts[_AID].RegTime) _AID = accounts[i];
		} else return 0;
	}

	function _isAccountExisted(uint32 _AID) internal view returns (bool _isExist) {
		return _AID != 0 && Accounts[_AID].AccountID == _AID;
	}

	function _isAffiliateExisted(bytes16 _Affiliate) internal view returns (bool _isExist) {
		return
			_Affiliate != bytes16(0) &&
			Affiliates[_Affiliate] != 0 &&
			Affiliates[_Affiliate] == Accounts[Affiliates[_Affiliate]].AccountID;
	}

	/*----------------------------------------------------------------------------------------------------*/

	function NumberOfAccount() public view virtual returns (uint32 _NumA) {
		return numAccount;
	}

	// Dashboard
	struct AccountInfoOf {
		uint32 AccountID;
		string Affiliate;
		address Address;
		uint32 RegistrationTime;
		bool AutoLevelingup;
	}

	function InfoOfAccount(uint32 _AID) public view virtual returns (AccountInfoOf memory _AccountInfoOf) {
		return
			_AccountInfoOf = AccountInfoOf({
				AccountID: _AID,
				Affiliate: string(abi.encode(Accounts[_AID].Affiliate)),
				Address: Accounts[_AID].Address,
				RegistrationTime: Accounts[_AID].RegTime,
				AutoLevelingup: _isAutoLevelUp(_AID)
			});
	}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./Library.sol";

abstract contract TBalance {
	// Pirce of level in each xprogram. 0: Promo, 1-15: level pirce
	uint256[16] public PirceOfLevel = [
		0,
		1e18,
		5e18,
		10e18,
		20e18,
		40e18,
		80e18,
		160e18,
		320e18,
		640e18,
		1250e18,
		2500e18,
		5000e18,
		10000e18,
		20000e18,
		40000e18
	];

	// BSC MAINNET
	address constant BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
	address constant USDT = address(0x55d398326f99059fF775485246999027B3197955);
	address constant USDC = address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
	address constant DAI = address(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);
	address constant WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // PancakeRouter

	constructor() {}

	mapping(uint32 => mapping(address => uint256)) balances; // [ACCOUNTID][TOKEN] -> balance
	// Recycle is required, recycle fee is equal to level cost (= PirceOfLevel)
	mapping(uint32 => uint256) LockedRecycle; // [ACCOUNTID] -> balance needs to be locked for recycles
	// Required to upgrade after the program's free cycle (Cycle 1: free, cycle 2: require locked, cycle 3: require upgrade level)
	mapping(uint32 => uint256) LockedUpgrade; // [ACCOUNTID] -> balance needs to be locked for required to upgrade level

	mapping(uint32 => uint256) public CommunityFund;
	uint32[] CFPending;
	bool public isCFActived = true;
	uint256 public CFRatio = 20; // Max = 20%

	// Upline is only rewarded when you complete your cycle and recycle
	// mapping(uint32 => uint256) LockedForShareReward; // [ACCOUNTID] -> balance is locked to send to upline in XProgram


	modifier OnlyToken(address _token) {
		require(_token == BUSD || _token == USDT || _token == USDC || _token == DAI, "Token not supported");
		_;
	}

	function _deposit(uint32 _AccountID, address _Token, uint256 _Amount) internal OnlyToken(_Token) {
		require(_Amount > 0, "amount can not zero");
		balances[_AccountID][_Token] += _Amount;
	}

	// them withdrawn to ETH
	function _withdrawn(uint32 _AccountID, address _Token, uint256 _Amount) internal OnlyToken(_Token) {
		require(_Amount > 0, "amount can not zero");
		uint256 BeforeBalance = balances[_AccountID][_Token];
		require(BeforeBalance >= _Amount, "withdrawn amount exceeds balance");

		balances[_AccountID][_Token] = BeforeBalance - _Amount;
	}

	function _transferToken(
		uint32 _fromAccount,
		uint32 _toAccount,
		address _Token,
		uint256 _Amount
	) internal OnlyToken(_Token) {
		require(_Amount > 0, "amount can not zero");
		uint256 fromBalance = balances[_fromAccount][_Token];
		require(fromBalance >= _Amount, "transfer amount exceeds balance");

		balances[_fromAccount][_Token] = fromBalance - _Amount;
		balances[_toAccount][_Token] += _Amount;
	}

	function _transferReward(uint32 _fromAccount, uint32 _toAccount, uint256 _Amount) internal {
		require(_Amount > 0, "amount can not zero");
	}

	function _TokenBalanceOf(uint32 _AccountID, address _Token) internal view returns (uint256 _BalanceOf) {
		return _BalanceOf = balances[_AccountID][_Token];
	}

	function _TotalBalanceOf(uint32 _AccountID) internal view returns (uint256 _BalanceOf) {
		_BalanceOf += balances[_AccountID][BUSD];
		_BalanceOf += balances[_AccountID][USDT];
		_BalanceOf += balances[_AccountID][USDC];
		return _BalanceOf += balances[_AccountID][DAI];
	}

	function _LockedRecycleOf(uint32 _AccountID) internal view returns (uint256 _Lock) {
		return LockedRecycle[_AccountID];
	}

	function _LockedUpgradeOf(uint32 _AccountID) internal view returns (uint256 _Lock) {
		return LockedUpgrade[_AccountID];
	}

	function _AvailableToUpgrade(uint32 _AccountID) internal view returns (uint256 _Available) {
		uint256 totalbalance = _TotalBalanceOf(_AccountID);
		uint256 lockedrecycle = _LockedRecycleOf(_AccountID);
		return totalbalance > lockedrecycle ? totalbalance - lockedrecycle : 0;
	}

	function _AvailableToWithdrawn(uint32 _AccountID) internal view returns (uint256 _Available) {
		uint256 locked = _LockedRecycleOf(_AccountID) + _LockedUpgradeOf(_AccountID);
		uint256 totalbalance = _TotalBalanceOf(_AccountID);
		return totalbalance > locked ? totalbalance - locked : 0;
	}

	/*----------------------------------------------------------------------------------------------------*/

	struct BalanceOf {
		uint256 BUSD;
		uint256 USDT;
		uint256 USDC;
		uint256 DAI;
		uint256 TotalBalances;
		uint256 LockedForRecycle;
		uint256 AvailableWithdrawn;
	}

	function BalanceOfAccount(uint32 _AccountID) public view virtual returns (BalanceOf memory _BalanceOf) {
		return
			_BalanceOf = BalanceOf({
				BUSD: _TokenBalanceOf(_AccountID, BUSD),
				USDT: _TokenBalanceOf(_AccountID, USDT),
				USDC: _TokenBalanceOf(_AccountID, USDC),
				DAI: _TokenBalanceOf(_AccountID, DAI),
				TotalBalances: _TotalBalanceOf(_AccountID),
				LockedForRecycle: _LockedRecycleOf(_AccountID),
				AvailableWithdrawn: _AvailableToWithdrawn(_AccountID)
			});
	}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "./Library.sol";

abstract contract TMatrix {
	uint32 RootID;

	struct SLTracking {
		uint32 F1SL2;
		uint32 F1SL5;
		uint32 F2SL2;
		uint32 F3SL2;
	}
	mapping(uint32 => SLTracking) SLTrack;

	mapping(uint32 => uint32) internal SLOf; // [NodeID] : SL index of
	mapping(uint32 => uint32) SID; // [NodeID] : Sponsor id of
	mapping(uint32 => mapping(uint8 => uint32)) UID; // [NodeID][MATRIX] : Upline id on matrix
	mapping(uint32 => mapping(uint8 => uint32[])) F1s; // [NodeID][MATRIX] : list F1 on matrix

	mapping(uint32 => mapping(uint8 => uint32)) XR; // [NODEID][MATRIX] : X of root on matrix
	mapping(uint32 => mapping(uint8 => uint32)) XS; // [NODEID][MATRIX] : X of sponsor on matrix

	constructor(uint32 _Starting) {
		require(_Starting != 0, "_Starting can not zero");
		InitializeMatrix(_Starting);
	}

	function InitializeMatrix(uint32 _Starting) private {
		SLOf[_Starting] = 1;
	}

	// Initialize new node for Matrixes
	function _InitAccountForMaxtrixes(
		uint32 _NodeID,
		uint32 _SponsorID,
		uint32 _UplineIDOnBINARY,
		uint32 _UplineIDOnTERNARY
	) internal {
		SID[_NodeID] = _SponsorID;
		SLOf[_NodeID] = 1;

		// Unilevel matrix
		UID[_NodeID][UNILEVEL] = _SponsorID;
		F1s[_SponsorID][UNILEVEL].push(_NodeID);

		// Update sponsor level for upline when node changes from SL1 to SL2
		if (F1s[_SponsorID][UNILEVEL].length == 3) _UpdateSponsorLevelForUpline(_NodeID);

		// Binary matrix
		(bool success, uint32 xofroot, uint32 xofsponsor) = _VerifyUplineID(_SponsorID, _UplineIDOnBINARY, BINARY);
		if (success && xofroot != 0 && xofsponsor != 0) {
			UID[_NodeID][BINARY] = _UplineIDOnBINARY;
			F1s[_UplineIDOnBINARY][BINARY].push(_NodeID);
			XR[_NodeID][BINARY] = xofroot;
			XS[_NodeID][BINARY] = xofsponsor;
		} else revert("Verify UplineID BINARY: fail");

		// Ternary matrix
		(success, xofroot, xofsponsor) = _VerifyUplineID(_SponsorID, _UplineIDOnTERNARY, TERNARY);
		if (success && xofroot != 0 && xofsponsor != 0) {
			UID[_NodeID][TERNARY] = _UplineIDOnTERNARY;
			F1s[_UplineIDOnTERNARY][TERNARY].push(_NodeID);
			XR[_NodeID][TERNARY] = xofroot;
			XS[_NodeID][TERNARY] = xofsponsor;
		} else revert("Verify UplineID TERNARY: fail");
	}

	// Verify UplineID & Caculated x of root and x of sponsor
	function _VerifyUplineID(
		uint32 _SponsorID,
		uint32 _UplineID,
		uint8 _MATRIX
	) internal view returns (bool _Success, uint32 _XOfRoot, uint32 _XOfSponsor) {
		if (F1s[_UplineID][_MATRIX].length >= _MATRIX) return (false, 0, 0); // Limited leg

		_XOfRoot = XR[_UplineID][_MATRIX] + 1; // From root to _UplineID (upline of new node)
		// _XOfSponsor - From _UplineID (upline of new node) to sponsor of new node

		while (true) {
			if (_UplineID != 0) {
				++_XOfSponsor;
				if (_UplineID == _SponsorID) break; // Sponsor found, is downline of sponsor
			} else {
				return (false, 0, 0); // == 0 is root, root found, is not downline of sponsor
			}
			_UplineID = UID[_UplineID][_MATRIX];
		}

		if (SID[_SponsorID] == 0) {
			if (_XOfSponsor != _XOfRoot) return (false, _XOfRoot, _XOfSponsor);
		} else {
			if (_XOfSponsor == _XOfRoot) return (false, _XOfRoot, _XOfSponsor);
		}

		_Success = true;
	}

	// Update sponsor level for upline when node changes from SL1 to SL2
	function _UpdateSponsorLevelForUpline(uint32 _NodeID) private {
		// Check ROOT ...
		uint32 s1 = SID[_NodeID];
		SLOf[s1] += 1 + SLTrack[s1].F1SL2; // Here: s1.SL max = 4

		uint32 s2 = SID[s1];
		if (s2 == 0) return;
		++SLTrack[s2].F1SL2;
		uint32 s2sl = SLOf[s2];
		bool s2sl5;
		if (s2sl >= 2 && s2sl <= 4) {
			++s2sl; // Here: s2.SL max = 5
			if (s2sl == 5) {
				s2sl += (SLTrack[s2].F2SL2 >= 9 ? 9 : SLTrack[s2].F2SL2);
				s2sl5 = true;
			}
			SLOf[s2] = s2sl; // Here: s2.SL max = 14
		}

		uint32 s3 = SID[s2];
		if (s3 == 0) return;
		++SLTrack[s3].F2SL2;
		uint32 s3sl = SLOf[s3];
		if (s2sl5 && ++SLTrack[s3].F1SL5 >= 10 && s3sl < 15) SLOf[s3] = 15;
		if (s3sl >= 5 && s3sl < 14) ++SLOf[s3]; // Here: s3.SL max = 14

		uint32 s4 = SID[s3];
		if (s4 == 0) return;
		if (++SLTrack[s4].F3SL2 >= 27 && SLOf[s4] < 15) SLOf[s4] = 15;
	}

	/*----------------------------------------------------------------------------------------------------*/

	// Tree view
	function SelectF1OfAccount(uint32 _NodeID, uint8 _MATRIX) public view virtual returns (uint32[] memory _NodeIDs) {
		return F1s[_NodeID][_MATRIX];
	}

	// Dashboard
	struct SponsorLevelOf {
		uint32 SponsorLevel;
		uint256 F1Count;
		uint32 F1SL2Above;
		uint32 F1SL5Above;
		uint32 F2SL2Above;
		uint32 F3SL2Above;
	}

	function SponsorLevelOfAccount(uint32 _NodeID) public view virtual returns (SponsorLevelOf memory _SponsorLevelOf) {
		return
			_SponsorLevelOf = SponsorLevelOf({
				SponsorLevel: SLOf[_NodeID], // Sponsor level is calculated on unilevel matrix
				F1Count: F1s[_NodeID][UNILEVEL].length, // Total F1
				F1SL2Above: SLTrack[_NodeID].F1SL2, // F1 has a sponsor level from SLevel 2 and above
				F1SL5Above: SLTrack[_NodeID].F1SL5,
				F2SL2Above: SLTrack[_NodeID].F2SL2,
				F3SL2Above: SLTrack[_NodeID].F3SL2
			});
	}

	// Node info
	struct InfoNode {
		uint32 SID;
		uint32 UB;
		uint32 UT;
		uint32 nF1B;
		uint32 nF1T;
		uint32 XRB;
		uint32 XRT;
		uint32 XSB;
		uint32 XST;
	}

	function NodeInfo(uint32 _ID) public view virtual returns (InfoNode memory _InfoNode) {
		return
			_InfoNode = InfoNode({
				SID: SID[_ID],
				UB: UID[_ID][BINARY],
				UT: UID[_ID][TERNARY],
				nF1B: uint32(F1s[_ID][BINARY].length),
				nF1T: uint32(F1s[_ID][TERNARY].length),
				/* For test */
				XRB: XR[_ID][BINARY],
				XRT: XR[_ID][TERNARY],
				XSB: XS[_ID][BINARY],
				XST: XS[_ID][TERNARY]
			});
	}

	function F1NodeInfo(uint32 _ID, uint8 _M) public view virtual returns (InfoNode[] memory _InfoNode) {
		uint32[] memory nodeids = SelectF1OfAccount(_ID, _M);
		uint256 len = nodeids.length;

		if (len > 0) {
			_InfoNode = new InfoNode[](len);
			for (uint32 i = 0; i < len; ++i) _InfoNode[i] = NodeInfo(i);
		}
	}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import './TAccount.sol';

contract Tuktu is TAccount {
	constructor(uint32 _Starting) TAccount(_Starting) {}

	modifier onlyAccountOwner(uint32 _AccountID) {
		require(msg.sender == _AddressOfAccount(_AccountID), 'Account: caller is not the owner');
		_;
	}

	modifier onlyAccountExisted(uint32 _AccountID) {
		require(_isAccountExisted(_AccountID), 'Account: does not existed');
		_;
	}

	fallback() external {}

	receive() external payable {}

	// Register with referral link of sponsor
	function Register(uint32 _SponsorID, uint32 _UplineIDOnBINARY, uint32 _UplineIDOnTERNARY, uint8 _LevelOn) public {
		require(_isAccountExisted(_SponsorID), 'SponsorID: does not existed');
		require(_isAccountExisted(_UplineIDOnBINARY), 'UplineID BINARY: does not existed');
		require(_isAccountExisted(_UplineIDOnTERNARY), 'UplineID TERNARY: does not existed');
		require(_LevelOn >= 1 && _LevelOn <= 15, 'Level on: out of range');

		_register(msg.sender, _SponsorID, _UplineIDOnBINARY, _UplineIDOnTERNARY, _LevelOn);
	}

	// Register for someone else, users can register for other users
	function Register(
		address _NewAccountAddress,
		uint32 _SponsorID,
		uint32 _UplineIDOnBINARY,
		uint32 _UplineIDOnTERNARY,
		uint8 _LevelOn
	) public {
		require(_NewAccountAddress != address(0), 'Registration: can not zero address');
		require(_isAccountExisted(_SponsorID), 'SponsorID: does not existed');
		require(_isAccountExisted(_UplineIDOnBINARY), 'UplineID BINARY: does not existed');
		require(_isAccountExisted(_UplineIDOnTERNARY), 'UplineID TERNARY: does not existed');
		require(_LevelOn >= 1 && _LevelOn <= 15, 'Level on: out of range');

		_register(_NewAccountAddress, _SponsorID, _UplineIDOnBINARY, _UplineIDOnTERNARY, _LevelOn);
	}

	function VerifyUplineID(
		uint32 _SponsorID,
		uint32 _UplineIDOnBINARY,
		uint32 _UplineIDOnTERNARY
	) public view returns (bool _Success) {
		require(_isAccountExisted(_SponsorID), 'SponsorID: does not existed');
		require(_isAccountExisted(_UplineIDOnBINARY), 'UplineID BINARY: does not existed');
		require(_isAccountExisted(_UplineIDOnTERNARY), 'UplineID TERNARY: does not existed');
		(bool success1, , ) = _VerifyUplineID(_SponsorID, _UplineIDOnBINARY, BINARY);
		(bool success2, , ) = _VerifyUplineID(_SponsorID, _UplineIDOnTERNARY, TERNARY);
		return success1 && success2;
	}

	/*----------------------------------------------------------------------------------------------------*/

	// Affiliate
	function AffiliateCheckAvailable(string memory _Affiliate) public view returns (bool _ReadyToUse) {
		require(bytes(_Affiliate).length != 0, 'Affiliate: can not empty');
		return !_isAffiliateExisted(bytes16(bytes(_Affiliate))); // true is ready to use
	}

	function AffiliateCreate(
		uint32 _AccountID,
		string memory _NewAffiliate
	) public onlyAccountOwner(_AccountID) onlyAccountExisted(_AccountID) {
		if (bytes(_NewAffiliate).length == 0) {
			// Generate new affiliate
			_AffiliateOfAccount(_AccountID) == bytes16(0)
				? _UpdateAffiliate(_AccountID, _AffiliateCreator())
				: revert('Affiliate: can not empty');
		} else {
			// User create new affiliate or change (/update) affiliate
			require(_isAffiliateExisted(bytes16(bytes(_NewAffiliate))) == false, 'Affiliate: existed');
			_UpdateAffiliate(_AccountID, bytes16(bytes(_NewAffiliate)));
		}
	}

	function AffiliateToAccount(string memory _Affiliate) public view returns (uint32 _AccountID) {
		require(bytes(_Affiliate).length != 0, 'Affiliate: can not empty');
		require(_isAffiliateExisted(bytes16(bytes(_Affiliate))), 'Affiliate: does not exist');
		return _AccountOfAffiliate(bytes16(bytes(_Affiliate)));
	}

	// Account transfer
	function ChangeAddress(
		uint32 _AccountID,
		address _NewAddress
	) public onlyAccountOwner(_AccountID) onlyAccountExisted(_AccountID) {
		require(_NewAddress != address(0), 'can not zezo address');
		require(_AddressOfAccount(_AccountID) != _NewAddress, 'same address already exists');
		_UpdateAddress(_AccountID, _NewAddress);
	}

	function AddressToAccount(address _Address) public view returns (uint32 _AccountID) {
		require(_Address != address(0), 'can not zero address');
		require(_GetLatestAccountsOf(_Address) != 0, 'unregistered address');
		return _GetLatestAccountsOf(_Address);
	}

	/*----------------------------------------------------------------------------------------------------*/

	// Dashboard, Account infomation
	function AccountsOfAddress(address _Address) public view returns (uint32[] memory _AccountIDs) {
		require(_Address != address(0), 'Dashboard: can not zero address');
		_AccountIDs = _AccountsOf(_Address);
	}

	function BalanceOfAccount(
		uint32 _AccountID
	) public view override onlyAccountExisted(_AccountID) returns (BalanceOf memory _BalanceOf) {
		return super.BalanceOfAccount(_AccountID);
	}

	function SponsorLevelOfAccount(
		uint32 _AccountID
	) public view override onlyAccountExisted(_AccountID) returns (SponsorLevelOf memory _SponsorLevelOf) {
		return super.SponsorLevelOfAccount(_AccountID);
	}

	function InfoOfAccount(
		uint32 _AccountID
	) public view override onlyAccountExisted(_AccountID) returns (AccountInfoOf memory _AccountInfoOf) {
		return super.InfoOfAccount(_AccountID);
	}

	// Select all F1 of account in each matrix for treeview
	function SelectF1OfAccount(
		uint32 _AccountID,
		uint8 _MATRIX
	) public view override onlyAccountExisted(_AccountID) returns (uint32[] memory _AccountIDs) {
		require(_MATRIX >= 1 && _MATRIX <= 3, 'Matrix: does not existed');
		return super.SelectF1OfAccount(_AccountID, _MATRIX);
	}

	/*----------------------------------------------------------------------------------------------------*/

	function NodeInfo(
		uint32 _AccountID
	) public view override onlyAccountExisted(_AccountID) returns (InfoNode memory _InfoNode) {
		return super.NodeInfo(_AccountID);
	}

	function F1NodeInfo(
		uint32 _AccountID,
		uint8 _MATRIX
	) public view override onlyAccountExisted(_AccountID) returns (InfoNode[] memory _InfoNode) {
		require(_MATRIX >= 1 && _MATRIX <= 3, 'Matrix: does not existed');
		return super.F1NodeInfo(_AccountID, _MATRIX);
	}

	function NumberOfAccount() public view override returns (uint32 _NumA) {
		// Registered count. It's not player and it's not x programer
		// One user has many accounts, an account has many xprograms, each xprogram has 15 level
		return super.NumberOfAccount();
	}

	/*----------------------------------------------------------------------------------------------------*/
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import './TMatrix.sol';
import './TBalance.sol';
import './TAccount.sol';
import './Library.sol';

abstract contract XProgram is TMatrix, TBalance {
	uint8 constant X3 = 1;
	uint8 constant X6 = 2;
	uint8 constant X7 = 3;
	uint8 constant X8 = 4;
	uint8 constant X9 = 5;

	uint8 constant Line1 = 1;
	uint8 constant Line2 = 2;
	uint8 constant Line3 = 3;

	// Level index: from 1 to 15
	// PirceOfLevel: from 1 to 15

	// [AccountID][XPRO][LEVEL][LINE-X][POS-Y] -> AccountID: downline of current cycle on line x and position y
	mapping(uint32 => mapping(uint8 => mapping(uint8 => mapping(uint8 => mapping(uint8 => uint32))))) LineXPosY;
	mapping(uint32 => mapping(uint8 => mapping(uint8 => mapping(uint8 => uint8)))) LineXCount; // [AccountID][XPRO][LEVEL][LINE-X] -> Count exist y position
	mapping(uint32 => mapping(uint8 => mapping(uint8 => uint32))) currentCycleUpline; // [AccountID][XPRO][LEVEL] -> Current upline ID in current cycle
	mapping(uint32 => mapping(uint8 => mapping(uint8 => uint32))) RecycleCount; // [AccountID][XPRO][LEVEL] -> Number of recycle on each level
	mapping(uint32 => mapping(uint8 => mapping(uint8 => bool))) LevelActived; // [AccountID][XPRO][LEVEL] -> Is the level activated or not

	mapping(uint32 => mapping(uint8 => mapping(uint8 => bool))) L4U; // Locked for required upgrade status
	mapping(uint32 => bool) ALU; // Auto level up

	uint256 public X7Line2Ratio = 30;
	uint256 public X7Line3Ratio = 70;
	uint256 public X9Line2Ratio = 30;
	uint256 public X9Line3Ratio = 70;

	using Uint32Array for uint32[];

	event NewCyclePosition(uint256 indexed timespan, uint32 indexed _AccountID, uint8 _XPro, uint8 _Level);
	event LostProfitOverLevel(uint256 indexed timespan, uint32 indexed _AccountID, uint8 _XPro, uint8 _Level);
	event Recycle(uint256 indexed timespan, uint32 indexed _AccountID, uint8 _XPro, uint8 _Level);
	event Upgraded(uint256 indexed timespan, uint32 indexed _AccountID, uint8 _XPro, uint8 _LevelTo);

	constructor(uint32 _Starting) {
		require(_Starting != 0, '_Starting can not zero');
		InitializeXProgram(_Starting);
	}

	function InitializeXProgram(uint32 _Starting) private {
		for (uint8 i = 1; i <= 15; ++i) {
			if (i <= 2) {
				currentCycleUpline[_Starting][X3][i] = 0;
				LevelActived[_Starting][X3][i] = true;
			}
			for (uint8 x = 2; x <= 5; ++x) {
				currentCycleUpline[_Starting][x][i] = 0;
				LevelActived[_Starting][x][i] = true;
			}
		}
		ALU[_Starting] = true;
	}

	// Init
	function _InitAccountForXProgram(uint32 _AccountID, uint8 _LevelOn) internal {
		_AccountActivationBatch(_AccountID, _LevelOn);
		ALU[_AccountID] = true;
	}

	// Account activation in batches of levels, for reg
	function _AccountActivationBatch(uint32 _AccountID, uint8 _LevelOn) internal {
		for (uint8 x = X3; x <= X9; ++x) {
			for (uint8 l = 1; l <= _LevelOn; ++l) {
				if (x != X3) {
					_FindCurrentCycleUpline(_AccountID, x, l);
					LevelActived[_AccountID][x][l] = true;
				} else {
					if (l <= 2) {
						_FindCurrentCycleUpline(_AccountID, X3, l);
						LevelActived[_AccountID][X3][l] = true;
					} else break;
				}
			}
		}
	}

	// Account upgrade level manually, fee from wallet
	function _UpgradeLevelManually(uint32 _AccountID, uint8 _XPro, uint8 _LevelTo) internal {
		if (LevelActived[_AccountID][_XPro][_LevelTo - 1]) {
			_UpgradeLevel(_AccountID, _XPro, _LevelTo);
		} else revert('Previous level has not been activated');
		// Kieemr tra locked
		// Nếu đang locked thì kiểm tra unlock và nâng cấp level
	}

	/*----------------------------------------------------------------------------------------------------*/

	// Upgrade level
	function _UpgradeLevel(uint32 _AccountID, uint8 _XPro, uint8 _LevelTo) internal {
		// Check balance of account
		if (_AvailableToUpgrade(_AccountID) >= PirceOfLevel[_LevelTo]) {
			_FindCurrentCycleUpline(_AccountID, _XPro, _LevelTo);
			LevelActived[_AccountID][_XPro][_LevelTo] = true;
			emit Upgraded(block.timestamp, _AccountID, _XPro, _LevelTo);

			// Upgraded: If locked before, then unlock
			_UnlockWhenUpgraded(_AccountID, _XPro, _LevelTo);

			// Auto level up: locked to upgrade to next level
			if (ALU[_AccountID]) {
				if (_LevelTo + 1 > 15) return;
				if (_XPro == X3 && _LevelTo + 1 > 2) return;
				if (LevelActived[_AccountID][_XPro][_LevelTo + 1]) return;

				_LockedToUpgrade(_AccountID, _XPro, _LevelTo + 1);
			}
		}
		// If balance not enough then locked to require upgrade level
		else _LockedToUpgrade(_AccountID, _XPro, _LevelTo);
	}

	function _LockedToUpgrade(uint32 _AccountID, uint8 _XPro, uint8 _Level) internal {
		if (L4U[_AccountID][_XPro][_Level] == false) {
			L4U[_AccountID][_XPro][_Level] = true;
			LockedUpgrade[_AccountID] += PirceOfLevel[_Level];
		}
	}

	function _UnlockWhenUpgraded(uint32 _AccountID, uint8 _XPro, uint8 _Level) internal {
		if (L4U[_AccountID][_XPro][_Level] == true) {
			L4U[_AccountID][_XPro][_Level] = false;
			LockedUpgrade[_AccountID] -= PirceOfLevel[_Level];
		}
	}

	function _Recycling(uint32 _AccountID, uint8 _XPro, uint8 _Level) internal {
		// Reset current cycle status and find new current upline for account recycling
		// Only on account recycling will the account be checked for the required upgrade

		// Recycling
		if (_XPro == X3) {
			//
		} else if (_XPro == X6) {
			//
		} else if (_XPro == X8) {
			//
		} else if (_XPro == X7) {
			//
		} else if (_XPro == X9) {
			for (uint8 i = 1; i <= 27; ++i) {
				LineXPosY[_AccountID][_XPro][_Level][3][i] = 0;
				if (i > 9) continue;
				LineXPosY[_AccountID][_XPro][_Level][2][i] = 0;
				if (i > 3) continue;
				LineXPosY[_AccountID][_XPro][_Level][1][i] = 0;
				LineXCount[_AccountID][_XPro][_Level][i] = 0;
			}
			currentCycleUpline[_AccountID][_XPro][_Level] = 0;

			++RecycleCount[_AccountID][_XPro][_Level];
			emit Recycle(block.timestamp, _AccountID, _XPro, _Level);
			_FindCurrentCycleUpline(_AccountID, _XPro, _Level); // New cycle

			// Check required upgrade level
			_CheckRequiredUpgradeLevel(_AccountID, _XPro, _Level);
		}
	}

	function _CheckRequiredUpgradeLevel(uint32 _AccountID, uint8 _XPro, uint8 _Level) internal {
		if (_Level >= 15) return;
		if (_XPro == X3 && _Level >= 2) return;
		if (LevelActived[_AccountID][_XPro][_Level + 1]) return;

		uint32 recyclecount = RecycleCount[_AccountID][_XPro][_Level];
		if (recyclecount > 2) return;

		// Cycle 1: free, cycle 2: require locked, cycle 3: require upgrade level
		if (recyclecount == 1) {
			if (ALU[_AccountID]) _UpgradeLevel(_AccountID, _XPro, _Level + 1);
			else _LockedToUpgrade(_AccountID, _XPro, _Level + 1); // Not auto and not locked then locked to require upgrade level
		} else _UpgradeLevel(_AccountID, _XPro, _Level + 1); // recyclecount == 2
	}

	function _ShareReward(uint32 _AccountID, uint8 _XPro, uint8 _Level) internal {
		if (_XPro == X3) {
			//
		} else if (_XPro == X6 || _XPro == X8) {
			//
		} else if (_XPro == X7 || _XPro == X9) {
			uint256 sr = PirceOfLevel[_Level];
			require(_LockedRecycleOf(_AccountID) >= sr, 'ShareReward: not enough balance to recycle');

			uint32 cu1 = currentCycleUpline[_AccountID][_XPro][_Level];
			if (cu1 == 0) return; // cu1 = 0 là _A = root : thì ko chia/làm gì cả

			if (RecycleCount[_AccountID][_XPro][_Level] > 0) LockedRecycle[_AccountID] -= sr; // unlocked

			uint32 cu2 = currentCycleUpline[cu1][_XPro][_Level];
			if (cu2 == 0) {
				_transferReward(_AccountID, cu1, sr); // cu2 = 0 là cu1 = root : cu1 nhận hết
				return;
			}

			uint32 cu3 = currentCycleUpline[cu2][_XPro][_Level];
			if (cu3 == 0) {
				_transferReward(_AccountID, cu2, sr); // cu3 = 0 là cu2 = root : cu2 nhận hết
				return;
			}

			uint256 acu2;
			uint256 acu3;
			if (_XPro == X7) {
				acu2 = (sr * X7Line2Ratio) / 100;
				acu3 = (sr * X7Line3Ratio) / 100;
				if (LineXPosY[cu2][X7][_Level][2][4] == _AccountID) LockedRecycle[cu2] += acu2; // lock for recycle
				if (LineXPosY[cu3][X7][_Level][3][8] == _AccountID) LockedRecycle[cu3] += acu3;
			} else {
				acu2 = (sr * X9Line2Ratio) / 100;
				acu3 = (sr * X9Line3Ratio) / 100;
				if (LineXPosY[cu2][X9][_Level][2][9] == _AccountID) LockedRecycle[cu2] += acu2;
				if (LineXPosY[cu3][X9][_Level][3][27] == _AccountID) LockedRecycle[cu3] += acu3;
			}

			if (isCFActived) {
				CommunityFund[_AccountID] += (CFRatio * (acu2 + acu3)) / 100;
				acu2 = ((100 - CFRatio) * acu2) / 100;
				acu3 = ((100 - CFRatio) * acu3) / 100;
				CFPending.AddNoDuplicate(_AccountID);
			}
			_transferReward(_AccountID, cu2, acu2);
			_transferReward(_AccountID, cu3, acu3);
		}
	}

	// Find current upline and update for _AccountID in cycle upline
	function _FindCurrentCycleUpline(uint32 _AccountID, uint8 _XPro, uint8 _Level) internal {
		uint32 cycleupline = _FindCycleUpline(_AccountID, _XPro, _Level);

		if (_XPro == X3) {
			//
		} else if (_XPro == X6) {
			//
		} else if (_XPro == X8) {
			//
		} else if (_XPro == X7) {
			//
		} else if (_XPro == X9) {
			if (LineXCount[cycleupline][_XPro][_Level][1] < 3) {
				// Line 1
				uint8 ay_x1C = ++LineXCount[cycleupline][_XPro][_Level][1]; // Position of _A on line 1 of C
				LineXPosY[cycleupline][_XPro][_Level][1][ay_x1C] = _AccountID; // Update XPro: _A on C (line 1 of C)

				uint32 B = currentCycleUpline[cycleupline][_XPro][_Level];
				uint32 A;
				if (B != 0) {
					uint8 cy_x1B;
					for (cy_x1B = 1; cy_x1B <= 3; ++cy_x1B) {
						if (LineXPosY[B][_XPro][_Level][1][cy_x1B] == cycleupline) {
							uint8 ay_x2B = (((cy_x1B - 1) * 3) + ay_x1C);
							LineXPosY[B][_XPro][_Level][2][ay_x2B] = _AccountID; // Update XPro: _A on B (line 2 of B)
							++LineXCount[B][_XPro][_Level][2];
							break;
						}
					}

					A = currentCycleUpline[B][_XPro][_Level];
					if (A != 0) {
						uint8 by_x1A;
						for (by_x1A = 1; by_x1A <= 3; ++by_x1A) {
							if (LineXPosY[A][_XPro][_Level][1][by_x1A] == B) {
								uint8 cy_x2A = (((by_x1A - 1) * 3) + cy_x1B);
								uint8 ay_x3A = (((cy_x2A - 1) * 3) + ay_x1C);
								LineXPosY[A][_XPro][_Level][3][ay_x3A] = _AccountID; // Update XPro: _A on A (line 3 of A)
								++LineXCount[A][_XPro][_Level][3];
								break;
							}
						}
					}
				}

				currentCycleUpline[_AccountID][_XPro][_Level] = cycleupline; // C
				_ShareReward(_AccountID, _XPro, _Level); // Share Reward
				if (A != 0 && LineXCount[A][_XPro][_Level][3] == 27) _Recycling(A, _XPro, _Level); // Recycling A
			} else if (LineXCount[cycleupline][_XPro][_Level][2] < 9) {
				// line 2
				uint8 ay_x2C = ++LineXCount[cycleupline][_XPro][_Level][2]; // Position of _A on line 2 of C
				LineXPosY[cycleupline][_XPro][_Level][2][ay_x2C] = _AccountID; // Update XPro: _A on C (line 2 of C)

				uint8 dy_x1C = ay_x2C % 3 == 0 ? (ay_x2C / 3) : ((ay_x2C / 3) + 1); // Position of D on line 1 of C
				uint32 currentUpline = LineXPosY[cycleupline][_XPro][_Level][1][dy_x1C]; // D: is current upline of _A

				uint8 ay_x1D = ay_x2C % 3 == 0 ? 3 : ay_x2C % 3; // Position of _A on line 1 of D
				LineXPosY[currentUpline][_XPro][_Level][1][ay_x1D] = _AccountID; // Update XPro: _A on D (line 1 of D)
				++LineXCount[currentUpline][_XPro][_Level][1];

				uint32 B = currentCycleUpline[cycleupline][_XPro][_Level];
				if (B != 0) {
					uint8 cy_x1B; // Position of C on line 1 of B
					for (cy_x1B = 1; cy_x1B <= 3; ++cy_x1B) {
						if (LineXPosY[B][_XPro][_Level][1][cy_x1B] == cycleupline) {
							uint8 dy_x2B = (((cy_x1B - 1) * 3) + dy_x1C);
							uint8 ay_x3B = (((dy_x2B - 1) * 3) + ay_x1D);
							LineXPosY[B][_XPro][_Level][3][ay_x3B] = _AccountID; // Update XPro: _A on B (line 3 of B)
							++LineXCount[B][_XPro][_Level][3];
							break;
						}
					}
				}

				currentCycleUpline[_AccountID][_XPro][_Level] = currentUpline; // D
				_ShareReward(_AccountID, _XPro, _Level); // Share Reward
				if (B != 0 && LineXCount[B][_XPro][_Level][3] == 27) _Recycling(B, _XPro, _Level); // Recycling B
			} else if (LineXCount[cycleupline][_XPro][_Level][3] < 27) {
				// line 3
				uint8 ay_x3C = ++LineXCount[cycleupline][_XPro][_Level][3]; // Position of _A on line 3 of C
				LineXPosY[cycleupline][_XPro][_Level][3][ay_x3C] = _AccountID; // Update XPro: _A on C (line 3 of C)

				uint8 ey_x2C = ay_x3C % 3 == 0 ? (ay_x3C / 3) : ((ay_x3C / 3) + 1); // Position of E on line 2 of C
				uint32 currentUpline = LineXPosY[cycleupline][_XPro][_Level][2][ey_x2C]; // E: is current upline of _A

				uint8 ay_x1E = ay_x3C % 3 == 0 ? 3 : ay_x3C % 3; // Position of _A on line 1 of E
				LineXPosY[currentUpline][_XPro][_Level][1][ay_x1E] = _AccountID; // Update XPro: _A on E (line 1 of E)
				++LineXCount[currentUpline][_XPro][_Level][1];

				uint32 D = currentCycleUpline[currentUpline][_XPro][_Level]; // D is current upline of E
				uint8 ey_x1D = (ey_x2C % 3 == 0 ? 3 : ey_x2C % 3); // Position of E on line 1 of D
				uint8 ay_x2D = (((ey_x1D - 1) * 3) + ay_x1E); // Position of _A on line 2 of D
				LineXPosY[D][_XPro][_Level][2][ay_x2D] = _AccountID; // Update XPro: _A on D (line 2 of D)
				++LineXCount[D][_XPro][_Level][2];

				currentCycleUpline[_AccountID][_XPro][_Level] = currentUpline; // E
				_ShareReward(_AccountID, _XPro, _Level); // Share Reward
				if (ay_x3C == 27) _Recycling(cycleupline, _XPro, _Level); // Recycling C
			}
		}

		if (currentCycleUpline[_AccountID][_XPro][_Level] == 0) revert('_FindCurrentCycleUpline: fail');
	}

	function _FindCycleUpline(uint32 _AccountID, uint8 _XPro, uint8 _Level) internal returns (uint32 _CycleUpline) {
		uint32 aSL = SLOf[_AccountID];
		uint8 matrix;
		if (_XPro == X7 || _XPro == X9) matrix = TERNARY;
		else if (_XPro == X6 || _XPro == X8) matrix = BINARY;
		else if (_XPro == X3) matrix = UNILEVEL;

		_CycleUpline = UID[_AccountID][matrix];
		if (_CycleUpline == 0) return _AccountID;

		while (true) {
			if (SLOf[_CycleUpline] >= aSL && LevelActived[_CycleUpline][_XPro][_Level] == true) return _CycleUpline;
			else emit LostProfitOverLevel(block.timestamp, _CycleUpline, _XPro, _Level);

			if (UID[_CycleUpline][matrix] == 0) return _CycleUpline;
			else _CycleUpline = UID[_CycleUpline][matrix];
		}
	}

	/*----------------------------------------------------------------------------------------------------*/

	function _isAutoLevelUp(uint32 _AccountID) internal view returns (bool _Auto) {
		return ALU[_AccountID];
	}

	function _UpdateAutoLevelUpStatus(uint32 _AccountID) internal {
		if (ALU[_AccountID]) {
			ALU[_AccountID] = false;

			if (LevelActived[_AccountID][X3][2] == false && RecycleCount[_AccountID][X3][1] == 0)
				_UnlockWhenUpgraded(_AccountID, X3, 2);

			for (uint8 x = X6; x <= X9; ++x)
				for (uint8 l = 2; l <= 15; ++l)
					if (LevelActived[_AccountID][x][l] == false) {
						// The first level is not activated yet
						// Only unlock on freecycle (requires level upgrade)
						if (RecycleCount[_AccountID][x][l - 1] == 0) _UnlockWhenUpgraded(_AccountID, x, l);
						break;
					}
		} else {
			ALU[_AccountID] = true;

			if (LevelActived[_AccountID][X3][2] == false) _LockedToUpgrade(_AccountID, X3, 2);
			for (uint8 x = X6; x <= X9; ++x)
				for (uint8 l = 2; l <= 15; ++l)
					if (LevelActived[_AccountID][x][l] == false) {
						// The first level is not activated yet
						_LockedToUpgrade(_AccountID, x, l);
						break;
					}
		}
	}
}