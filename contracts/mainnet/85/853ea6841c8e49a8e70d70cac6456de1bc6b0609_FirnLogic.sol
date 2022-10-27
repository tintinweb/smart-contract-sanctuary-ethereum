// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

import "./FirnBase.sol";
import "./DepositVerifier.sol";
import "./TransferVerifier.sol";
import "./WithdrawalVerifier.sol";
import "./Utils.sol";

contract FirnLogic {
    using Utils for uint256;
    using Utils for Utils.Point;

    mapping(bytes32 => uint64) _lastRollOver;
    bytes32[] _nonces; // would be more natural to use a mapping (really a set), but they can't be deleted / reset!
    uint64 _lastGlobalUpdate = 0; // will be also used as a proxy for "current epoch", seeing as rollovers will be anticipated

    uint256 constant EPOCH_LENGTH = 60;

    FirnBase immutable _base;
    DepositVerifier immutable _deposit;
    TransferVerifier immutable _transfer;
    WithdrawalVerifier immutable _withdrawal;

    event RegisterOccurred(address indexed sender, bytes32 indexed account, uint32 amount);
    event DepositOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D, address indexed source, uint32 amount); // amount not indexed
    event TransferOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D);
    event WithdrawalOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D, uint32 amount, address indexed destination, bytes data);

    address _owner;
    address _treasury;
    uint32 _fee;

    // some duplication here, but this is less painful than trying to retrieve it from the IP verifier / elsewhere.
    bytes32 immutable _gX;
    bytes32 immutable _gY;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner.");
        _;
    }

    constructor(address payable base_, address deposit_, address transfer_, address withdrawal_) {
        _owner = msg.sender;
        _base = FirnBase(base_);
        _deposit = DepositVerifier(deposit_);
        _transfer = TransferVerifier(transfer_);
        _withdrawal = WithdrawalVerifier(withdrawal_);

        Utils.Point memory gTemp = Utils.mapInto("g");
        _gX = gTemp.x;
        _gY = gTemp.y;
    }

    function administrate(address owner_, address treasury_, uint32 fee_) external onlyOwner {
        _owner = owner_;
        _treasury = treasury_;
        _fee = fee_;
    }

    function g() internal view returns (Utils.Point memory) {
        return Utils.Point(_gX, _gY);
    }

    function rollOver(bytes32 Y, uint64 epoch) internal {
        if (_lastRollOver[Y] < epoch) {
            Utils.Point[2] memory acc;
            (acc[0].x, acc[0].y) = _base.acc(Y, 0);
            (acc[1].x, acc[1].y) = _base.acc(Y, 1);
            Utils.Point[2] memory pending;
            (pending[0].x, pending[0].y) = _base.pending(Y, 0);
            (pending[1].x, pending[1].y) = _base.pending(Y, 1);
            acc[0] = acc[0].add(pending[0]);
            acc[1] = acc[1].add(pending[1]);
            delete pending;
            _base.setAcc(Y, acc);
            _base.setPending(Y, pending);
            _lastRollOver[Y] = epoch;
        }
    }

    function touch(bytes32 Y, uint32 credit, uint64 epoch) internal {
        // could save a few operations if we check for the special case that current.epoch == epoch.
        FirnBase.Info memory current;
        (current.epoch, current.index, current.amount) = _base.info(Y);
        if (current.epoch > 0) { // will only be false for registration...?
            _base.setList(current.epoch, current.index, _base.lists(current.epoch, _base.lengths(current.epoch) - 1)); // list[current.index] = list[list.length - 1];
            _base.popList(current.epoch); // lists[current.epoch].pop();
            if (_base.lengths(current.epoch) == 0) _base.removeEpoch(current.epoch); // if (lists[current.epoch].length == 0) remove(current.epoch);
            else if (current.index < _base.lengths(current.epoch)) {
                // else if (current.index < lists[current.epoch].length) info[lists[current.epoch][current.index]].index = current.index;
                FirnBase.Info memory other;
                (other.epoch, other.index, other.amount) = _base.info(_base.lists(current.epoch, current.index));
                other.index = current.index;
                _base.setInfo(_base.lists(current.epoch, current.index), other);
            }
        }
        current.epoch = epoch;
        current.amount += credit; // implicit conversion of RHS to uint64?
        if (!_base.exists(epoch)) {
            _base.insertEpoch(epoch);
        }
        current.index = uint64(_base.lengths(epoch)); // uint64(lists[epoch].length);
        _base.setInfo(Y, current);
        _base.pushList(epoch, Y); // lists[epoch].push(Y);
    }

    function simulateAccounts(bytes32[] calldata Y, uint32 epoch) external view returns (bytes32[2][] memory result) {
        // interestingly, we lose no efficiency by accepting compressed, because we never have to decompress.
        result = new bytes32[2][](Y.length);
        for (uint256 i = 0; i < Y.length; i++) {
            Utils.Point[2] memory acc;
            (acc[0].x, acc[0].y) = _base.acc(Y[i], 0);
            (acc[1].x, acc[1].y) = _base.acc(Y[i], 1);
            if (_lastRollOver[Y[i]] < epoch) {
                Utils.Point[2] memory pending;
                (pending[0].x, pending[0].y) = _base.pending(Y[i], 0);
                (pending[1].x, pending[1].y) = _base.pending(Y[i], 1);
                acc[0] = acc[0].add(pending[0]);
                acc[1] = acc[1].add(pending[1]);
            }
            result[i][0] = Utils.compress(acc[0]);
            result[i][1] = Utils.compress(acc[1]);
        }
    }

    function register(bytes32 Y, bytes32[2] calldata signature) external payable {
        require(msg.value >= 1e16, "Must be at least 0.010 ETH.");
        require(msg.value % 1e15 == 0, "Must be a multiple of 0.001 ETH.");

        uint64 epoch = uint64(block.timestamp / EPOCH_LENGTH);

        uint32 credit = uint32(msg.value / 1e15); // >= 10.
        (bool success,) = payable(_base).call{value: msg.value}(""); // forward $ to base
        require(success, "Forwarding funds to base failed.");
        require(address(_base).balance <= 1e15 * 0xFFFFFFFF, "Escrow pool now too large.");
        Utils.Point[2] memory pending;
        (pending[0].x, pending[0].y) = _base.pending(Y, 0);
        (pending[1].x, pending[1].y) = _base.pending(Y, 1);
        pending[0] = pending[0].add(g().mul(credit)); // convert to uint256?
        _base.setPending(Y, pending);

        Utils.Point memory pub = Utils.decompress(Y);
        Utils.Point memory K = g().mul(uint256(signature[1])).add(pub.mul(uint256(signature[0]).neg()));
        uint256 c = uint256(keccak256(abi.encode("Welcome to Firn.", address(this), Y, K))).mod();
        require(bytes32(c) == signature[0], "Signature failed to verify.");
        touch(Y, credit, epoch);

        emit RegisterOccurred(msg.sender, Y, credit);
    }

    function deposit(bytes32[N] calldata Y, bytes32[N] calldata C, bytes32 D, bytes calldata proof) external payable {
        // not doing a minimum amount here... the idea is that this function can't be used to force your way into the tree.
        require(msg.value % 1e15 == 0, "Must be a multiple of 0.001 ETH.");
        uint64 epoch = uint64(block.timestamp / EPOCH_LENGTH);
        uint32 credit = uint32(msg.value / 1e15); // can't overflow, by the above.
        (bool success,) = payable(_base).call{value: msg.value}(""); // forward $ to base
        require(success, "Forwarding funds to base failed.");
        require(address(_base).balance <= 1e15 * 0xFFFFFFFF, "Escrow pool now too large.");

        Utils.Statement memory statement;
        statement.D = Utils.decompress(D);
        for (uint256 i = 0; i < N; i++) {
            rollOver(Y[i], epoch);

            statement.Y[i] = Utils.decompress(Y[i]);
            statement.C[i] = Utils.decompress(C[i]);
            // mutate their pending, in advance of success.
            Utils.Point[2] memory pending;
            (pending[0].x, pending[0].y) = _base.pending(Y[i], 0);
            (pending[1].x, pending[1].y) = _base.pending(Y[i], 1);
            pending[0] = pending[0].add(statement.C[i]);
            pending[1] = pending[1].add(statement.D);
            _base.setPending(Y[i], pending);
            FirnBase.Info memory info;
            (info.epoch,,) = _base.info(Y[i]);
            require(info.epoch > 0, "Only cached accounts allowed.");
            touch(Y[i], credit, epoch); // weird question whether this should be 0 or credit... revisit.
        }

        _deposit.verify(credit, statement, Utils.deserializeDeposit(proof));

        emit DepositOccurred(Y, C, D, msg.sender, credit);
    }

    function transfer(bytes32[N] calldata Y, bytes32[N] calldata C, bytes32 D, bytes32 u, uint64 epoch, uint32 tip, bytes calldata proof) external {
        require(epoch == block.timestamp / EPOCH_LENGTH, "Wrong epoch."); // conversion of RHS to uint64 is unnecessary / redundant

        if (_lastGlobalUpdate < epoch) {
            _lastGlobalUpdate = epoch;
            delete _nonces;
        }
        for (uint256 i = 0; i < _nonces.length; i++) {
            require(_nonces[i] != u, "Nonce already seen.");
        }
        _nonces.push(u);

        Utils.Statement memory statement;
        statement.D = Utils.decompress(D);
        for (uint256 i = 0; i < N; i++) {
            rollOver(Y[i], epoch);

            statement.Y[i] = Utils.decompress(Y[i]);
            statement.C[i] = Utils.decompress(C[i]);
            Utils.Point[2] memory acc;
            (acc[0].x, acc[0].y) = _base.acc(Y[i], 0);
            (acc[1].x, acc[1].y) = _base.acc(Y[i], 1);
            statement.CLn[i] = acc[0].add(statement.C[i]);
            statement.CRn[i] = acc[1].add(statement.D);
            // mutate their pending, in advance of success.
            Utils.Point[2] memory pending;
            (pending[0].x, pending[0].y) = _base.pending(Y[i], 0);
            (pending[1].x, pending[1].y) = _base.pending(Y[i], 1);
            pending[0] = pending[0].add(statement.C[i]);
            pending[1] = pending[1].add(statement.D);
            _base.setPending(Y[i], pending);
            FirnBase.Info memory info;
            (info.epoch,,) = _base.info(Y[i]);
            require(info.epoch > 0, "Only cached accounts allowed.");
            touch(Y[i], 0, epoch);
        }
        statement.epoch = epoch;
        statement.u = Utils.decompress(u);
        statement.fee = tip;

        _transfer.verify(statement, Utils.deserializeTransfer(proof));

        _base.pay(msg.sender, uint256(tip) * 1e15, ""); // use all gas here... no reason not to

        emit TransferOccurred(Y, C, D);
    }

    function withdraw(bytes32[N] calldata Y, bytes32[N] calldata C, bytes32 D, bytes32 u, uint64 epoch, uint32 amount, uint32 tip, bytes calldata proof, address destination, bytes calldata data) external {
        require(epoch == block.timestamp / EPOCH_LENGTH, "Wrong epoch."); // conversion of RHS to uint64 is unnecessary. // could supply epoch ourselves; check early to save gas

        if (_lastGlobalUpdate < epoch) {
            _lastGlobalUpdate = epoch;
            delete _nonces;
        }
        for (uint256 i = 0; i < _nonces.length; i++) {
            require(_nonces[i] != u, "Nonce already seen.");
        }
        _nonces.push(u);

        emit WithdrawalOccurred(Y, C, D, amount, destination, data); // emit here, because of stacktoodeep.

        Utils.Statement memory statement;
        statement.D = Utils.decompress(D);
        for (uint256 i = 0; i < N; i++) {
            bytes32 Y_i = Y[i]; // necessary for stacktoodeep
            rollOver(Y_i, epoch);

            statement.Y[i] = Utils.decompress(Y_i);
            statement.C[i] = Utils.decompress(C[i]);
            Utils.Point[2] memory acc;
            (acc[0].x, acc[0].y) = _base.acc(Y_i, 0);
            (acc[1].x, acc[1].y) = _base.acc(Y_i, 1);
            statement.CLn[i] = acc[0].add(statement.C[i]);
            statement.CRn[i] = acc[1].add(statement.D);
            // mutate their pending, in advance of success.
            Utils.Point[2] memory pending;
            (pending[0].x, pending[0].y) = _base.pending(Y_i, 0);
            (pending[1].x, pending[1].y) = _base.pending(Y_i, 1);
            pending[0] = pending[0].add(statement.C[i]);
            pending[1] = pending[1].add(statement.D);
            _base.setPending(Y_i, pending);
            FirnBase.Info memory info;
            (info.epoch,,) = _base.info(Y_i);
            require(info.epoch > 0, "Only cached accounts allowed.");
        }
        uint32 burn = amount / _fee;
        statement.epoch = epoch; // implicit conversion to uint256
        statement.u = Utils.decompress(u);
        statement.fee = tip + burn; // implicit conversion to uint256

        uint256 salt = uint256(keccak256(abi.encode(destination, data))); // .mod();
        _withdrawal.verify(amount, statement, Utils.deserializeWithdrawal(proof), salt);

        _base.pay{gas: 10000}(msg.sender, uint256(tip) * 1e15, ""); // payable(msg.sender).transfer(uint256(tip) * 1e15);
        _base.pay(_treasury, uint256(burn) * 1e15, ""); // (bool success,) = payable(_treasury).call{value: uint256(burn) * 1e15}("");
        _base.pay(destination, uint256(amount) * 1e15, data);
    }
}