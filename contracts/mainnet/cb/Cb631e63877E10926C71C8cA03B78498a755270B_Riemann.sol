/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IHasher {
    function poseidon(uint256[2] calldata input) external pure returns (uint256);
}

interface IDepositVerifier {
    function verifyProof(uint256[2] calldata a, uint256[2][2] calldata b, uint256[2] calldata c, uint256[3] calldata input) external view returns (bool);
}

interface IWithdrawVerifier {
    function verifyProof(uint256[2] calldata a, uint256[2][2] calldata b, uint256[2] calldata c, uint256[5] calldata input) external view returns (bool);
}

interface ISplitVerifier {
    function verifyProof(uint256[2] calldata a, uint256[2][2] calldata b, uint256[2] calldata c, uint256[3] calldata input) external view returns (bool);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Riemann is ReentrancyGuard {
    uint256 public constant Q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public constant MAX_DEPTH = 32;
    uint256 public constant MAX_LEAVES = 5;
    address private constant NATIVE_TOKEN = address(0);

    IHasher public immutable hasher;
    IDepositVerifier public immutable depositVerifier;
    IWithdrawVerifier public immutable withdrawVerifier;
    ISplitVerifier public immutable splitVerifier;

    uint256 public immutable depth;
    uint256 public immutable zero;
    uint256 public immutable maxCount;

    uint256 public root;
    uint256 public count;

    // leaf => bool
    mapping(uint256 => bool) public commitments;
    // nullifierHash => bool
    mapping(uint256 => bool) public nullifierHashes;

    // depth => index => node
    mapping(uint256 => mapping(uint256 => uint256)) private _nodes;
    // depth => zero
    mapping(uint256 => uint256) private _zeroes;

    event NewLeaf(uint256 indexed leaf, uint256 index);
    event Deposit(address indexed account, address token, uint256 amount);
    event Withdraw(uint256 indexed nullifierHash);

    constructor(IHasher _hasher, IDepositVerifier _depositVerifier, IWithdrawVerifier _withdrawVerifier, ISplitVerifier _splitVerifier, uint256 _depth, uint256[] memory zeroes) {
        require(_depth > 0 && _depth <= MAX_DEPTH, "depth invalid");

        uint256 length = zeroes.length;
        require(length == _depth + 1, "zeroes invalid");

        hasher = _hasher;
        depositVerifier = _depositVerifier;
        withdrawVerifier = _withdrawVerifier;
        splitVerifier = _splitVerifier;
    
        depth = _depth;
        maxCount = 2 ** _depth;
        zero = zeroes[0];

        // i: 0 ~ depth - 1
        // zeroes[i + 1] = hasher.poseidon([zeroes[i], zeroes[i]]);

        for (uint256 i = 0; i < depth;) {
            _zeroes[i] = zeroes[i];

            unchecked {
                ++i;
            }
        }

        root = zeroes[depth];
    }

    function deposit(uint256[8] calldata _proof, uint256[] calldata _commitments, address token, uint256 amount) external payable nonReentrant {
        uint256 length = _commitments.length;
        require(length > 0 && length <= MAX_LEAVES, "commitments invalid");

        if (token == NATIVE_TOKEN) {
            require(amount == msg.value, "amount invalid");
        } else {
            IERC20 _token = IERC20(token);
            address self = address(this);
            uint256 balance = _token.balanceOf(self);
            _safeTransferFrom(token, msg.sender, self, amount);
            uint256 receivedAmount = _token.balanceOf(self) - balance;
            require(receivedAmount == amount, "amount invalid");
        }

        uint256 commitmentsHash = _calcCommitmentsHash(_commitments);
        require(depositVerifier.verifyProof(
            [_proof[0], _proof[1]],
            [[_proof[2], _proof[3]], [_proof[4], _proof[5]]],
            [_proof[6], _proof[7]],
            [commitmentsHash, uint256(uint160(token)), amount]
        ), "proof invalid");

        _insertLeaves(_commitments);

        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(
        uint256[8] calldata _proof,
        uint256 _nullifierHash,
        address _token,
        address payable _recipient,
        uint256 _amount,
        address payable _fund,
        uint256 _fee
    ) external {
        require(!nullifierHashes[_nullifierHash], "nullifierHash invalid!");
        require(_amount > _fee, "amount invalid!");

        uint256 messageHash = uint256(keccak256(abi.encode(_token, _recipient, _amount, _fund, _fee))) >> 8;
        
        require(withdrawVerifier.verifyProof(
            [_proof[0], _proof[1]],
            [[_proof[2], _proof[3]], [_proof[4], _proof[5]]],
            [_proof[6], _proof[7]],
            [root, _nullifierHash, uint256(uint160(_token)), _amount, messageHash]
        ), "proof invalid");

        nullifierHashes[_nullifierHash] = true;

        if (_token == NATIVE_TOKEN) {
            _transferNative(_recipient, _amount - _fee);
            if (_fee > 0) {
                _transferNative(_fund, _fee);
            }
        } else {
            _safeTransfer(_token, _recipient, _amount - _fee);
            if (_fee > 0) {
                _safeTransfer(_token, _fund, _fee);
            }
        }

        emit Withdraw(_nullifierHash);
    }

    function split(uint256[8] calldata _proof, uint256[] calldata _commitments, uint256 _nullifierHash) external nonReentrant {
        uint256 length = _commitments.length;
        require(length > 0 && length <= MAX_LEAVES, "commitments invalid");

        uint256 commitmentsHash = _calcCommitmentsHash(_commitments);
        require(splitVerifier.verifyProof(
            [_proof[0], _proof[1]],
            [[_proof[2], _proof[3]], [_proof[4], _proof[5]]],
            [_proof[6], _proof[7]],
            [root, _nullifierHash,  commitmentsHash]
        ), "proof invalid");

        nullifierHashes[_nullifierHash] = true;
        _insertLeaves(_commitments);
    }

    function isSpent(uint256 _nullifierHash) external view returns (bool) {
        return nullifierHashes[_nullifierHash];
    }

    function isSpents(uint256[] calldata _nullifierHashes) external view returns (bool[] memory result) {
        result = new bool[](_nullifierHashes.length);
        for (uint256 i = 0; i < _nullifierHashes.length; i++) {
            result[i] = nullifierHashes[_nullifierHashes[i]];
        }
    }

    function getLeaves(uint256 start, uint256 end) external view returns (uint256[] memory result) {
        if(start > end) {
            (start, end) = (end, start);
        }

        uint256 length = end - start;
        result = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = _nodes[0][start + i];
        }
    }

    function _insertLeaves(uint256[] calldata _leaves) private {
        uint256 length = _leaves.length;
        require(length + count < maxCount, "tree will be full");

        uint256 start = count;
        uint256 end = start + length;
        uint256 i;
        uint256 j;
        uint256 node;
        uint256 temp;

        for (; i < length;) {
            node = _leaves[i];
            require(!commitments[node] && node < Q, "leaf invalid!");

            commitments[node] = true;
            _nodes[0][count] = node;

            emit NewLeaf(node, count);
            unchecked {
                ++i;
                ++count;
            }
        }

        for (i = 0; i < depth;) {
            unchecked {
                start -= (start & 1);
                end += (end & 1);
            }

            for (j = start; j < end;) {
                temp = _nodes[i][j + 1];
                node = hasher.poseidon([_nodes[i][j], temp != 0 ? temp : _zeroes[i]]);

                if (i + 1 == depth) {
                    root = node;
                } else {
                    _nodes[i + 1][j >> 1] = node;
                }

                unchecked {
                    j += 2;
                }
            }

            start >>= 1;
            end >>= 1;

            unchecked {
                ++i;
            }
        }
    }

    function _calcCommitmentsHash(uint256[] calldata _commitments) private view returns (uint256) {
        if (_commitments.length == 1) {
            return _commitments[0];
        }
        
        uint256 commitmentsHash = hasher.poseidon([_commitments[0], _commitments[1]]);
        for (uint256 i = 2; i < _commitments.length;) {
            commitmentsHash = hasher.poseidon([commitmentsHash, _commitments[i]]);

            unchecked {
                ++i;
            }
        }
        
        return commitmentsHash;
    }

    function _transferNative(address payable to, uint256 value) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value}("");
        require(success, "transfer native fail");
    }

    function _safeTransfer(address token, address to, uint value) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer fail");
    }

    function _safeTransferFrom(address token, address from, address to, uint value) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "transfer from fail");
    }
}