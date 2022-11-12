// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

import "./EpochTree.sol";
import "./DepositVerifier.sol";
import "./TransferVerifier.sol";
import "./WithdrawalVerifier.sol";
import "./Utils.sol";

contract Firn is EpochTree {
    using Utils for uint256;
    using Utils for Utils.Point;

    mapping(bytes32 => Utils.Point[2]) _acc; // main account mapping
    mapping(bytes32 => Utils.Point[2]) _pending; // storage for pending transfers
    mapping(bytes32 => uint64) _lastRollOver;
    bytes32[] _nonces; // would be more natural to use a mapping (really a set), but they can't be deleted / reset!
    uint64 _lastGlobalUpdate = 0; // will be also used as a proxy for "current epoch", seeing as rollovers will be anticipated

    uint256 constant EPOCH_LENGTH = 60;

    DepositVerifier immutable _deposit;
    TransferVerifier immutable _transfer;
    WithdrawalVerifier immutable _withdrawal;

    event RegisterOccurred(address indexed sender, bytes32 indexed account, uint32 amount);
    event DepositOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D, address indexed source, uint32 amount); // amount not indexed
    event TransferOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D);
    event WithdrawalOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D, uint32 amount, address indexed destination, bytes data);

    address _treasury;
    uint32 _fee;

    // some duplication here, but this is less painful than trying to retrieve it from the IP verifier / elsewhere.
    bytes32 immutable _gX;
    bytes32 immutable _gY;

    struct Info { // try to save storage space by using smaller int types here
        uint64 epoch;
        uint64 index; // index in the list
        uint64 amount;
    }
    mapping(bytes32 => Info) public info; // needs to be public, for reader
    mapping(uint64 => bytes32[]) public lists; // needs to be public, for reader

    function lengths(uint64 epoch) external view returns (uint256) { // see https://ethereum.stackexchange.com/a/20838.
        return lists[epoch].length;
    }

    bytes32 internal constant _ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    modifier onlyOwner() {
        require(msg.sender == _getAdmin(), "Caller is not the owner.");
        _;
    }

    constructor(address deposit_, address transfer_, address withdrawal_) {
        _deposit = DepositVerifier(deposit_);
        _transfer = TransferVerifier(transfer_);
        _withdrawal = WithdrawalVerifier(withdrawal_);

        Utils.Point memory gTemp = Utils.mapInto("g");
        _gX = gTemp.x;
        _gY = gTemp.y;
    }

    function administrate(address treasury_, uint32 fee_) external onlyOwner {
        _treasury = treasury_;
        _fee = fee_;
    }

    function g() internal view returns (Utils.Point memory) {
        return Utils.Point(_gX, _gY);
    }

    function rollOver(bytes32 Y, uint64 epoch) internal {
        if (_lastRollOver[Y] < epoch) {
            _acc[Y][0] = _acc[Y][0].add(_pending[Y][0]);
            _acc[Y][1] = _acc[Y][1].add(_pending[Y][1]);
            delete _pending[Y]; // pending[Y] = [Utils.G1Point(0, 0), Utils.G1Point(0, 0)];
            _lastRollOver[Y] = epoch;
        }
    }

    function touch(bytes32 Y, uint32 credit, uint64 epoch) internal {
        // could save a few operations if we check for the special case that current.epoch == epoch.
        bytes32[] storage list; // declare here not for efficiency, but to avoid shadowing warning
        Info storage current = info[Y];
        if (current.epoch > 0) { // will only be false for registration...?
            list = lists[current.epoch];
            list[current.index] = list[list.length - 1];
            list.pop();
            if (list.length == 0) remove(current.epoch);
            else if (current.index < list.length) info[list[current.index]].index = current.index;
        }
        current.epoch = epoch;
        current.amount += credit; // implicit conversion of RHS to uint64?
        if (!exists(epoch)) {
            insert(epoch);
        }
        list = lists[epoch];
        current.index = uint32(list.length);
        list.push(Y);
    }

    function simulateAccounts(bytes32[] calldata Y, uint32 epoch) external view returns (bytes32[2][] memory result) {
        // interestingly, we lose no efficiency by accepting compressed, because we never have to decompress.
        result = new bytes32[2][](Y.length);
        for (uint256 i = 0; i < Y.length; i++) {
            Utils.Point[2] memory temp;
            temp[0] = _acc[Y[i]][0];
            temp[1] = _acc[Y[i]][1];
            if (_lastRollOver[Y[i]] < epoch) {
                temp[0] = temp[0].add(_pending[Y[i]][0]);
                temp[1] = temp[1].add(_pending[Y[i]][1]);
            }
            result[i][0] = Utils.compress(temp[0]);
            result[i][1] = Utils.compress(temp[1]);
        }
    }

    function register(bytes32 Y, bytes32[2] calldata signature) external payable {
        require(msg.value >= 1e16, "Must be at least 0.010 ETH.");
        require(msg.value % 1e15 == 0, "Must be a multiple of 0.001 ETH.");

        uint64 epoch = uint64(block.timestamp / EPOCH_LENGTH);

        require(address(this).balance <= 1e15 * 0xFFFFFFFF, "Escrow pool now too large.");
        uint32 credit = uint32(msg.value / 1e15); // >= 10.
        _pending[Y][0] = _pending[Y][0].add(g().mul(credit)); // convert to uint256?

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
        require(address(this).balance <= 1e15 * 0xFFFFFFFF, "Escrow pool now too large.");
        uint32 credit = uint32(msg.value / 1e15); // can't overflow, by the above.

        Utils.Statement memory statement;
        statement.D = Utils.decompress(D);
        for (uint256 i = 0; i < N; i++) {
            rollOver(Y[i], epoch);

            statement.Y[i] = Utils.decompress(Y[i]);
            statement.C[i] = Utils.decompress(C[i]);
            // mutate their pending, in advance of success.
            _pending[Y[i]][0] = _pending[Y[i]][0].add(statement.C[i]);
            _pending[Y[i]][1] = _pending[Y[i]][1].add(statement.D);
            require(info[Y[i]].epoch > 0, "Only cached accounts allowed.");
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
            statement.CLn[i] = _acc[Y[i]][0].add(statement.C[i]);
            statement.CRn[i] = _acc[Y[i]][1].add(statement.D);
            // mutate their pending, in advance of success.
            _pending[Y[i]][0] = _pending[Y[i]][0].add(statement.C[i]);
            _pending[Y[i]][1] = _pending[Y[i]][1].add(statement.D);
            require(info[Y[i]].epoch > 0, "Only cached accounts allowed.");
            touch(Y[i], 0, epoch);
        }
        statement.epoch = epoch;
        statement.u = Utils.decompress(u);
        statement.fee = tip;

        _transfer.verify(statement, Utils.deserializeTransfer(proof));

        payable(msg.sender).transfer(uint256(tip) * 1e15);

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
            bytes32 Y_i = Y[i];
            rollOver(Y_i, epoch);

            statement.Y[i] = Utils.decompress(Y_i);
            statement.C[i] = Utils.decompress(C[i]);
            statement.CLn[i] = _acc[Y_i][0].add(statement.C[i]);
            statement.CRn[i] = _acc[Y_i][1].add(statement.D);
            // mutate their pending, in advance of success.
            _pending[Y_i][0] = _pending[Y_i][0].add(statement.C[i]);
            _pending[Y_i][1] = _pending[Y_i][1].add(statement.D);
            require(info[Y_i].epoch > 0, "Only cached accounts allowed.");
        }
        uint32 fee = amount / _fee;
        statement.epoch = epoch; // implicit conversion to uint256
        statement.u = Utils.decompress(u);
        statement.fee = tip + fee; // implicit conversion to uint256

        uint256 salt = uint256(keccak256(abi.encode(destination, data))); // .mod();
        _withdrawal.verify(amount, statement, Utils.deserializeWithdrawal(proof), salt);

        payable(msg.sender).transfer(uint256(tip) * 1e15);
        (bool success, ) = payable(_treasury).call{value: uint256(fee) * 1e15}("");
        require(success, "External treasury call failed.");
        (success, ) = payable(destination).call{value: uint256(amount) * 1e15}(data);
        require(success, "External withdrawal call failed.");
    }
}

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}