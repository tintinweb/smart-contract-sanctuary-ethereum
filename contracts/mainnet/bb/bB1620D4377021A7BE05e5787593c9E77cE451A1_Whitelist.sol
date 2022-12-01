/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Whitelist {
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public owners;
    uint256 public totalWallets;

    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    //keccak256(Whitelist(address destination,uint256 value,bytes data,uint256 nonce,address executor,uint256 gasLimit))
    bytes32 constant TXTYPE_HASH = 0x88f833e90bbd309b4b3b256d9cdfabccf4894a1db90323558daa6d4a028b8f9a;

    bytes32 DOMAIN_SEPARATOR; // hash for EIP712, computed from contract address

    // EIP712 Precomputed hashes:
    //keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 constant EIP712DOMAINTYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    //keccak256("Securitize Wallet Whitelisting for Securitize ID")
    bytes32 constant NAME_HASH = 0xab27eb9b14178c92da4fcc5b0bce46a3a63877f5dc047c68cc5c1f1f3071f460;

    //keccak256("1")
    bytes32 constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    //keccak256("Securitize Whitelist SALT")
    bytes32 constant SALT = 0xd141745c012721d4e0effaa49816da5ed2c817bf752d467ac00bc7ef96406874;

    modifier onlyOwners() {
        require(
            owners[msg.sender],
            "Not Authorized"
        );
        _;
    }

    constructor() {
        owners[msg.sender] = true;
        owners[address(this)] = true;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAINTYPE_HASH,
                NAME_HASH,
                VERSION_HASH,
                block.chainid,
                this,
                SALT
            )
        );
    }

    function addOwner(address _newOwner) public onlyOwners {
        owners[_newOwner] = true;
    }

    function removeOwner(address _owner) public onlyOwners {
        owners[_owner] = false;
    }

    function addWalletFromOwner(address _wallet) public onlyOwners {
        require(!whitelisted[_wallet], 'Wallet already whitelisted');
        whitelisted[_wallet] = true;
        totalWallets++;
    }

    function addWallet(address _wallet, uint256 _blockLimit) public onlyOwners {
        require(!whitelisted[_wallet], 'Wallet already whitelisted');
        require(block.number <= _blockLimit, 'Transaction too old');
        whitelisted[_wallet] = true;
        totalWallets++;
    }

    function removeWalletFromOwner(address _wallet) public onlyOwners {
        require(whitelisted[_wallet], 'Wallet not in the whitelist');
        whitelisted[_wallet] = false;
        totalWallets--;
    }

    function removeWallet(address _wallet) public {
        require(msg.sender == _wallet, 'Not wallet owner');
        require(whitelisted[_wallet], 'Wallet not in the whitelist');
        whitelisted[_wallet] = false;
        totalWallets--;
    }

    function isWhitelisted(address _wallet) public view returns (bool) {
        return whitelisted[_wallet];
    }

    function getTotalWallets() public view returns (uint256) {
        return totalWallets;
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    function executeAddWallet(
        uint8 _sigV,
        bytes32 _sigR,
        bytes32 _sigS,
        bytes memory _data,
        uint256 _gasLimit
    ) public {
        address destination = address(this);
        // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
        bytes32 txInputHash = keccak256(
            abi.encode(
                TXTYPE_HASH,
                destination,
                0,
                keccak256(_data),
                0,
                ZERO_ADDRESS,
                _gasLimit
            )
        );

        bytes32 totalHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash)
        );

        address recovered = ecrecover(totalHash, _sigV, _sigR, _sigS);
        require(owners[recovered], 'Invalid signature per verification');

        bool success = false;

        assembly {
            success := call(
            _gasLimit,
            destination,
            0,
            add(_data, 0x20),
            mload(_data),
            0,
            0
            )
        }

        require(success, "transaction was not executed");
    }
}