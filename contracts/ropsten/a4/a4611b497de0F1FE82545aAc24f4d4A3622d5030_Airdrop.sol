// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCX {
  function balanceOf(address owner) external view returns (uint);
  function transferFrom(address from, address to, uint256 value) external;
}

contract Airdrop {

  struct Data {
    address from;
    address token;
    uint128 valuePerClaim;
    uint128 timestamp;
  }

	address public owner;
  uint32 public latestRef;

	mapping (uint32 => Data) public refData;
	mapping (uint32 => mapping (address => uint32)) public claimed;
	mapping (address => uint32[]) private drops;

	constructor() {
		owner = msg.sender;
	}

	modifier ensureOwner {
		require(owner == msg.sender); _;
	}

	event Dropped(uint32 ref, address indexed token);
	event Claimed(uint32 ref, address indexed token, address indexed to);

	function drop(uint32 ref, address from, address token, uint128 valuePerClaim, address[] calldata owners) ensureOwner external {
		require(refData[ref].timestamp == 0, 'ref');
    latestRef = ref;
		refData[ref] = Data({
			from: from,
			token: token,
			valuePerClaim: valuePerClaim,
			timestamp: uint128(block.timestamp)
		});
		for (uint i = 0; i < owners.length; i++) {
			drops[owners[i]].push(ref);
      claimed[ref][owners[i]] = 1;
		}

		emit Dropped(ref, token);
	}

	function claim(uint32 ref) external {
		require(claimed[ref][msg.sender] == 1, 'claim');
		claimed[ref][msg.sender] = uint32(block.timestamp);

		IERCX(refData[ref].token).transferFrom(refData[ref].from, msg.sender, refData[ref].valuePerClaim);

		emit Claimed(ref, refData[ref].token, msg.sender);
	}

	function setOwner(address _owner) ensureOwner external {
		owner = _owner;
	}

	function dropsOf(address _owner) external view returns (uint32[] memory, Data[] memory, uint[] memory) {
		Data[] memory _refDatas = new Data[](drops[_owner].length);
		uint[] memory _claims = new uint[](drops[_owner].length);

		for (uint i = 0; i < drops[_owner].length; i++) {
			_refDatas[i] = refData[drops[_owner][i]];
			_claims[i] = claimed[drops[_owner][i]][_owner];
		}

		return (drops[_owner], _refDatas, _claims);
	}

	function balancesOf(address _owner, address[] calldata tokens) external view returns (uint[] memory) {
		uint[] memory b = new uint[](tokens.length);
		for (uint i = 0; i < b.length; i++) {
			b[i] = IERCX(tokens[i]).balanceOf(_owner);
		}

		return b;
	}
}