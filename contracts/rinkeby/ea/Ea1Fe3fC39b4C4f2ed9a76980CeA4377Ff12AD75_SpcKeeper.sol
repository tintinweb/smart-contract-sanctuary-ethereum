// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MerkleProof.sol";
import "./SafeTransfer.sol";


contract SpcKeeper is SafeTransfer{

    address public constant distributionToken = address(
        0x3013E04923209D4BBcBCcaDbefbE7aa4E6bb72c7
    );

    uint256 public maximumDrop;
    uint256 public spcdropCount;

    uint256 public totalRequired;
    uint256 public totalCollected;

    address public masterAccount;

    struct Keeper {
        bytes32 root;
        uint256 total;
        uint256 claimed;
    }

    mapping(address => bool) public dropsWorkers;
    mapping(address => bool) public claimWorkers;

    mapping(uint256 => string) public ipfsData;
    mapping(bytes32 => Keeper) public spcdrops;

    mapping(bytes32 => mapping(address => bool)) public hasClaimed;

    modifier onlyMaster() {
        require(
            msg.sender == masterAccount,
            'SpcKeeper: invalid master'
        );
        _;
    }

    modifier onlyDropsWorker() {
        require(
            dropsWorkers[msg.sender] == true,
            'SpcKeeper: invalid drops worker'
        );
        _;
    }

    modifier onlyClaimWorker() {
        require(
            claimWorkers[msg.sender] == true,
            'SpcKeeper: invalid claim worker'
        );
        _;
    }

    event Withdraw(
        address indexed account,
        uint256 amount
    );

    event NewSpcdrop(
        bytes32 indexed hash,
        address indexed master,
        string indexed ipfsAddress,
        uint256 total
    );

    event Claimed(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    constructor(
        address _masterAccount,
        address _claimWorker,
        address _dropsWorker,
        uint256 _maximumDrop
    ) {
        masterAccount = _masterAccount;

        claimWorkers[_claimWorker] = true;
        dropsWorkers[_dropsWorker] = true;

        maximumDrop = _maximumDrop;
    }

    function changeMaximumDrop(
        uint256 _newMaximumDrop
    )
        external
        onlyMaster
    {
        maximumDrop = _newMaximumDrop;
    }

    function createSpcDrop(
        bytes32 _root,
        uint256 _total,
        string calldata _ipfsAddress
    )
        external
        onlyDropsWorker
    {
        require(
            _total > 0,
            'SpcKeeper: invalid total'
        );

        bytes32 hash = getHash(
            _ipfsAddress
        );

        require(
            spcdrops[hash].total == 0,
            'SpcKeeper: already created'
        );

        spcdrops[hash] = Keeper({
            root: _root,
            total: _total,
            claimed: 0
        });

        spcdropCount = spcdropCount + 1;

        ipfsData[spcdropCount] = _ipfsAddress;

        totalRequired = totalRequired + _total;

        emit NewSpcdrop(
            _root,
            masterAccount,
            _ipfsAddress,
            _total
        );
    }

    function getHash(
        string calldata _ipfsAddress
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _ipfsAddress
            )
        );
    }

    function isClaimed(
        bytes32 _hash,
        address _account
    )
        public
        view
        returns (bool)
    {
        return hasClaimed[_hash][_account];
    }

    function getClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    )
        external
    {
        _doClaim(
            _hash,
            _index,
            _amount,
            msg.sender,
            _merkleProof
        );
    }

    function getClaimBulk(
        bytes32[] calldata _hash,
        uint256[] calldata _index,
        uint256[] calldata _amount,
        bytes32[][] calldata _merkleProof
    )
        external
    {
        for (uint256 i = 0; i < _hash.length; i++) {
            _doClaim(
                _hash[i],
                _index[i],
                _amount[i],
                msg.sender,
                _merkleProof[i]
            );
        }
    }

    function giveClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        address _account,
        bytes32[] calldata _merkleProof
    )
        external
        onlyClaimWorker
    {
        _doClaim(
            _hash,
            _index,
            _amount,
            _account,
            _merkleProof
        );
    }

    function giveClaimBulk(
        bytes32[] calldata _hash,
        uint256[] calldata _index,
        uint256[] calldata _amount,
        address[] calldata _account,
        bytes32[][] calldata _merkleProof
    )
        external
        onlyClaimWorker
    {
        for (uint256 i = 0; i < _hash.length; i++) {
            _doClaim(
                _hash[i],
                _index[i],
                _amount[i],
                _account[i],
                _merkleProof[i]
            );
        }
    }

    function _doClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        address _account,
        bytes32[] calldata _merkleProof
    )
        private
    {
        require(
            isClaimed(_hash, _account) == false,
            'SpcKeeper: already claimed'
        );

        require(
            _amount <= maximumDrop,
            'SpcKeeper: invalid amount'
        );

        bytes32 node = keccak256(
            abi.encodePacked(
                _index,
                _account,
                _amount
            )
        );

        require(
            MerkleProof.verify(
                _merkleProof,
                spcdrops[_hash].root,
                node
            ),
            'SpcKeeper: invalid proof'
        );

        spcdrops[_hash].claimed = spcdrops[_hash].claimed + _amount;

        totalCollected = totalCollected + _amount;

        require(
            spcdrops[_hash].total >= spcdrops[_hash].claimed,
            'SpcKeeper: claim excess'
        );

        _setClaimed(
            _hash,
            _account
        );

        safeTransfer(
            distributionToken,
            _account,
            _amount
        );

        emit Claimed(
            _index,
            _account,
            _amount
        );
    }

    function _setClaimed(
        bytes32 _hash,
        address _account
    )
        private
    {
        hasClaimed[_hash][_account] = true;
    }

    function withdrawFunds(
        uint256 _amount
    )
        external
        onlyMaster
    {
        safeTransfer(
            distributionToken,
            masterAccount,
            _amount
        );

        emit Withdraw(
            masterAccount,
            _amount
        );
    }

    function changeMaster(
        address _newMaster
    )
        external
        onlyMaster
    {
        masterAccount = _newMaster;
    }

    function changeClaimWorker(
        address _claimWorker,
        bool _isWorker
    )
        external
        onlyMaster
    {
        claimWorkers[_claimWorker] = _isWorker;
    }

    function changeDropsWorker(
        address _dropsWorker,
        bool _isWorker
    )
        external
        onlyMaster
    {
        dropsWorkers[_dropsWorker] = _isWorker;
    }

    function getBalance() public view returns(uint256) {
        return IERC20(distributionToken).balanceOf(address(this));
    }

    function showRemaining(
        bytes32 _hash
    )
        public
        view
        returns (uint256)
    {
        return spcdrops[_hash].total - spcdrops[_hash].claimed;
    }

    function showExcess(
        bytes32 _hash
    )
        external
        view
        returns (int256)
    {
        return int256(getBalance()) - int256(showRemaining(_hash));
    }

    function showRemaining()
        public
        view
        returns (uint256)
    {
        return totalRequired - totalCollected;
    }

    function showExcess()
        external
        view
        returns (int256)
    {
        return int256(getBalance()) - int256(showRemaining());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SafeTransfer {

    bytes4 constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
      internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            'TransferHelper: TRANSFER_FAILED'
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees)
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}