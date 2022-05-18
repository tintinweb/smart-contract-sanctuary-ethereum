// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract BridgeCore {
    address public owner;
    address private pendingOwner;
    bytes32 public constant PERMIT_TYPE_HASH = 0x65ad8b067c3f44412403886927c7578708b814943af80f48764dc4b9450c01ee;
    bytes32 public DOMAIN_SEPARATOR;
    WSDInterface public wsd;
    mapping(address => bool) public blackList;
    mapping(address => uint) public nonces;

    event OwnerChanged(address owner, address newOwner);
    event WSDAddressChanged(address wsd, address newWsd);
    event IncreasedBalance(address indexed account, uint256 amount, string ethAddress);
    event DecreasedBalance(address indexed account, uint256 amount);
    event AddedToBlackList(address account);
    event RemovedFromBlackList(address account);
    event Withdrawn(address indexed account, uint256 amount);

    modifier ownerOnly() {
        require(msg.sender == owner, "Access denied");
        _;
    }

    constructor(address wsd_, uint32 salt) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("BridgeCore")),
                keccak256(bytes('1')),
                salt,
                address(this)
            )
        );

        owner = msg.sender;
        wsd = WSDInterface(wsd_);
        emit OwnerChanged(address(0), owner);
        emit WSDAddressChanged(address(0), wsd_);
    }

    function changeOwner(address newOwner_) external ownerOnly {
        owner = newOwner_;

        emit OwnerChanged(owner, pendingOwner);
    }

    function changeWSD(address newWSD_) external ownerOnly {
        emit WSDAddressChanged(address(wsd), newWSD_);
        wsd = WSDInterface(newWSD_);
    }

    function addToBlackList(address account) external ownerOnly {
        blackList[account] = true;
        emit AddedToBlackList(account);
    }

    function removeFromBlackList(address account) external ownerOnly {
        delete blackList[account];
        emit RemovedFromBlackList(account);
    }

    function withdraw(uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns (address){
        require(blackList[msg.sender] == false, "Withdraw: user is blocked");
        require(deadline >= block.timestamp, 'Withdraw expired.');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPE_HASH, owner, msg.sender, value, nonces[msg.sender]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0));

        wsd.transfer(msg.sender, value);

        emit Withdrawn(msg.sender, value);

        return recoveredAddress;
    }

    // Helpful math functions
    function safe96(uint256 n, string memory errorMessage)
    private
    pure
    returns (uint96)
    {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) private pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
}

// WSD Token interface
interface WSDInterface {
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool);

    function transfer(address dst, uint256 rawAmount) external returns (bool);
}