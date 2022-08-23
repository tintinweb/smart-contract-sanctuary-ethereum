// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
pragma abicoder v2;

contract MultiSig {
    address[] public signers;
    uint256 public requireConfirmations;

    uint256 public nonce;
    mapping(uint256 => Tx) public nonceToTx;
    mapping(uint256 => mapping(address => bool)) public txConfirmeers;

    struct Tx {
        address proposer;
        uint256 confirmations;
        bool executed;
        uint256 deadline;
        address txAddress;
        uint256 value;
        bytes txData;
    }

    event newProposal(address indexed proposer, uint256 indexed id);
    event Executed(
        address indexed executor,
        uint256 indexed id,
        bool indexed success
    );

    constructor(address[] memory _signers, uint256 _requireConfirmations) {
        require(_signers.length > 0, "Any signer");
        require(isUnique(_signers), "Duplicate address");
        require(_requireConfirmations <= _signers.length, "Not enough signer");

        signers = _signers;
        requireConfirmations = _requireConfirmations;
    }

    receive() external payable {}

    function proposeTx(
        uint256 _deadline,
        address _txAddress,
        uint256 _value,
        bytes memory _txData
    ) external onlySigners {
        require(_deadline > block.timestamp, "Time out");

        Tx memory _tx = Tx({
            proposer: msg.sender,
            confirmations: 0,
            executed: false,
            deadline: _deadline,
            txAddress: _txAddress,
            value: _value,
            txData: _txData
        });

        nonceToTx[nonce] = _tx;
        emit newProposal(msg.sender, nonce);
        nonce++;
    }

    function confirmTx(uint256 _nonce) external onlySigners txCheck(_nonce) {
        require(!txConfirmeers[_nonce][msg.sender], "Already approved.");
        require(nonceToTx[_nonce].deadline > block.timestamp, "Time out");

        nonceToTx[_nonce].confirmations++;
        txConfirmeers[_nonce][msg.sender] = true;
    }

    function rejectTx(uint256 _nonce) external onlySigners txCheck(_nonce) {
        require(txConfirmeers[_nonce][msg.sender], "Already non approved.");
        require(nonceToTx[_nonce].deadline > block.timestamp, "Time out");

        nonceToTx[_nonce].confirmations--;
        txConfirmeers[_nonce][msg.sender] = false;
    }

    function deleteTx(uint256 _nonce) external onlySigners txCheck(_nonce) {
        require(nonceToTx[_nonce].proposer == msg.sender, "Not tx owner");
        require(
            nonceToTx[_nonce].confirmations < requireConfirmations,
            "Already confirmed."
        );

        nonceToTx[_nonce] = Tx(address(0), 0, true, 0, address(0), 0, " ");
    }

    function executeTx(uint256 _nonce)
        external
        onlySigners
        txCheck(_nonce)
        returns (bool)
    {
        require(nonceToTx[_nonce].deadline > block.timestamp, "Time out");
        require(
            nonceToTx[_nonce].confirmations >= requireConfirmations,
            "Not confirmed."
        );
        require(
            nonceToTx[_nonce].value <= address(this).balance,
            "insufficient balance"
        );

        Tx storage _tx = nonceToTx[_nonce];

        _tx.executed = true;

        (bool txSuccess, ) = _tx.txAddress.call{value: _tx.value}(_tx.txData);

        if (!txSuccess) _tx.executed = false;

        emit Executed(msg.sender, _nonce, txSuccess);
        return txSuccess;
    }

    function isUnique(address[] memory arr) private pure returns (bool) {
        for (uint256 i = 0; i < arr.length - 1; i++) {
            for (uint256 y = i + 1; y < arr.length; y++) {
                require(arr[i] != arr[y], "Duplicate address.");
            }
        }
        return true;
    }

    modifier onlySigners() {
        bool signer = false;
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == msg.sender) signer = true;
        }
        require(signer, "Not signer");
        _;
    }

    modifier txCheck(uint256 _nonce) {
        require(_nonce < nonce, "Not exists");
        require(!nonceToTx[_nonce].executed, "Already executed");
        _;
    }
}