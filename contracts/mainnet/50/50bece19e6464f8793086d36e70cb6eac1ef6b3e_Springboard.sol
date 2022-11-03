/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity ^0.8.17;

interface Wisp {
    function ClaimRank(uint256 term) external;
    function ClaimMintRewardAndShare(address owner) external;
    function die(address owner) external;
}

contract Springboard {
    event Deployed(address addr);

    bool _mutex;
    bytes _bootstrap;

    bytes _pendingRuntimeCode;
    
    address private owner;    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor(bytes memory bootstrap) public {
        owner = msg.sender;
        _bootstrap = bootstrap;
    }

    function getBootstrap() public view returns (bytes memory bootstrap) {
        return bootstrap;
    }

    function _getAddress(bytes32 salt) internal view returns (address addr) {
        uint8 preamble = 0xff;
        bytes32 initCodeHash = keccak256(abi.encodePacked(_bootstrap));
        bytes32 hash = keccak256(abi.encodePacked(preamble, address(this), salt, initCodeHash));
        return address(uint160(uint256(hash)));
    }

    function getWispAddress(address addr, uint256 i) public view returns (address wispAddress) {
        return _getAddress(keccak256(abi.encodePacked(addr, i)));
    }

    function _ClaimRank(bytes32 salt, uint256 term) internal {
        require(!_mutex);
        _mutex = true;

        bytes memory bootstrap = _bootstrap;

        uint256 value = msg.value;

        address wisp;
        assembly {
            wisp := create2(value, add(bootstrap, 0x20), mload(bootstrap), salt)
        }

        Wisp(wisp).ClaimRank(term);

        Wisp(wisp).die(msg.sender);

        _mutex = false;

        //emit Deployed(wisp);
    }

    function BClaimRank(uint256 start, uint256 n, uint256 term) public payable {
        for (uint256 i=0; i<n; i++) {
            if(term > 0) {
                _ClaimRank(keccak256(abi.encodePacked(msg.sender, start + i)), term);
            } else {
                _ClaimRank(keccak256(abi.encodePacked(msg.sender, start + i)), i+1);
            }
        }
    }
    
    function _ClaimMintRewardAndShare(bytes32 salt, address owner) internal {
        require(!_mutex);
        _mutex = true;

        bytes memory bootstrap = _bootstrap;

        uint256 value = msg.value;

        address wisp;
        assembly {
            wisp := create2(value, add(bootstrap, 0x20), mload(bootstrap), salt)
        }

        Wisp(wisp).ClaimMintRewardAndShare(owner);

        Wisp(wisp).die(msg.sender);

        _mutex = false;

        //emit Deployed(wisp);
    }
    
    function BclaimMintRewardAndShare(uint256 start, uint256 n) public payable {
        for (uint256 i=0; i<n; i++) {
            _ClaimMintRewardAndShare(keccak256(abi.encodePacked(msg.sender, start + i)), msg.sender);
        }
    }

    function getPendingRuntimeCode() public view returns (bytes memory runtimeCode) {
        return _pendingRuntimeCode;
    }
    
    function setPendingRuntimeCode(bytes memory runtimeCode)public payable isOwner{
        _pendingRuntimeCode = runtimeCode;
    }
}