// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "./Wallet.sol";
import "./IVerifier.sol";

contract WalletFactory {
    address public owner;
    IVerifier public verifier;

    constructor(address _owner, IVerifier _verifier) {
        owner = _owner;
        verifier = _verifier;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event DeployedWallet(address indexed owner, address indexed walletAddress);

    function deploy(address walletOwner) external {
        // onlyOwner should be used here in a production setting
        address walletAddress = address(new Wallet(verifier, owner));

        emit DeployedWallet(walletOwner, walletAddress);
    }

    function changeVerifier(IVerifier _verifier) external {
        verifier = _verifier;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "./IVerifier.sol";

contract Wallet {
    struct TransactionObject {
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
        address from;
        bytes32 r;
        uint8 v;
        bytes32 s;
    }

    struct TransactionAction {
        address destContract;
        uint256 value;
        bytes data;
    }

    IVerifier verifier;
    address owner;

    bytes32 constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 USERACTION_TYPEHASH =
        keccak256("UserAction(address destContract,uint256 value,bytes data)");

    constructor(IVerifier _verifier, address _owner) {
        verifier = _verifier;
        owner = _owner;
    }

    function execute(
        TransactionObject memory transaction,
        uint256[] memory pubInputs,
        bytes memory proof
    ) external {
        require(verifier.verify(pubInputs, proof), "zk proof not correct");
        require(_checkTxRawSig(transaction), "original tx not signed by user");

        // TODO: binding of public input to transaction destination address
        // requires(pubInputs[5] == transaction.to);

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success);
    }

    /// Only can be called by the owner of this wallet to perform general action
    /// eg. withdrawal of tokens
    function executeEip712(
        TransactionAction memory action,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _verifyUserActions(action, v, r, s);
        (bool success, ) = action.destContract.call{value: action.value}(
            action.data
        );
        require(success);
    }

    function _checkTxRawSig(
        TransactionObject memory transaction
    ) internal returns (bool) {
        // TODO: implement logic

        // rlp transaction object without r,s,v
        // keccak256(rlp)
        // ecrecover hash and r,s,v to get address
        // check if address == from address
        return true;
    }

    function _verifyUserActions(
        TransactionAction memory actions,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 eip712Tx = _generateEIP712Tx(actions);
        address derivedOwner = ecrecover(eip712Tx, v, r, s);
        require(derivedOwner == owner);
    }

    function _generateEIP712Tx(
        TransactionAction memory action
    ) internal view returns (bytes32) {
        bytes32 userVoteHash = keccak256(
            abi.encode(
                USERACTION_TYPEHASH,
                action.destContract,
                action.value,
                action.data
            )
        );
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Wallet"),
                block.chainid,
                address(this)
            )
        );
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, userVoteHash)
            );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

interface IVerifier {
    function verify(
        uint256[] memory pubInputs,
        bytes memory proof
    ) external view returns (bool);
}