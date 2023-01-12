// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./preSale.sol";

interface Pre {
    function Dex(
        bool _enabled,
        uint256 _dexRate,
        uint8 _liquidity,
        uint64 _lockUpTime
    ) external;

    function createPreSale(
        bool _whitelist,
        address _token,
        uint256 _rate,
        uint256 _amount,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minVal,
        uint256 _maxVal,
        uint64 _startTime,
        uint64 _endTime,
        address owner
    ) external returns (bool);

    function setVesting(address _vestingContract) external;
}

contract FactoryPreSale {
    event NewPreSale(address preSale);
    mapping(address => address) public preSale;

    struct Sale {
        bool whitelist;
        uint256 rate;
        uint256 amount;
        uint64 startTime;
        uint64 endTime;
        uint256 minVal;
        uint256 maxVal;
        uint256 softCap;
        uint256 hardCap;
    }

    struct AutoDex {
        bool enabled;
        uint256 rate;
        uint8 liquidity;
        uint64 lockUpTime;
    }

    struct Vest {
        uint64 startTime;
        uint8 startPercent;
        uint64 cliffTime;
        uint8 cliffPercent;
    }

    function createPreSale(
        AutoDex calldata _autoDex,
        Sale calldata _sale,
        Vest calldata _vest,
        address _token,
        bool vesting
    ) public {
        require(preSale[_token] == address(0), "PreSale already exists");
        PreSale preSaleContract = new PreSale(_token);
        Pre(address(preSaleContract)).createPreSale(
            _sale.whitelist,
            _token,
            _sale.rate,
            _sale.amount,
            _sale.softCap,
            _sale.hardCap,
            _sale.minVal,
            _sale.maxVal,
            _sale.startTime,
            _sale.endTime,
            msg.sender
        );
        preSale[_token] = address(preSaleContract);
        address sendTo;
        uint256 amount;
        if (vesting) {
            VestingWallet vestingContract = new VestingWallet(
                address(preSaleContract),
                _vest.startTime,
                _vest.cliffTime,
                _vest.startPercent,
                _vest.cliffPercent,
                _token
            );
            amount = IERC20(_token).balanceOf(msg.sender);
            sendTo = address(vestingContract);
            Pre(address(preSaleContract)).setVesting(address(vestingContract));
        } else {
            amount = _sale.amount;
            sendTo = address(preSaleContract);
        }

        IERC20(_token).transferFrom(msg.sender, sendTo, amount);

        if (_autoDex.enabled) {
            Pre(address(preSaleContract)).Dex(
                _autoDex.enabled,
                _autoDex.rate,
                _autoDex.liquidity,
                _autoDex.lockUpTime
            );
        }

        emit NewPreSale(address(preSaleContract));
    }
}

contract VestingWallet {
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _erc20Released;
    address private immutable _beneficiary;
    uint64 private immutable _start;
    uint64 private immutable _duration;
    uint8 private immutable _startPercent;
    uint8 private immutable _cyclePercent;
    address private token;
    bool private _released;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint8 startPercent,
        uint8 cyclePercent,
        address _token
    ) payable {
        require(
            beneficiaryAddress != address(0),
            "VestingWallet: beneficiary is zero address"
        );
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
        _startPercent = startPercent;
        _cyclePercent = cyclePercent;
        token = _token;
    }

    receive() external payable virtual {}

    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    function start() public view virtual returns (uint64) {
        return _start;
    }

    function duration() public view virtual returns (uint64) {
        return _duration;
    }

    function released() public view virtual returns (uint256) {
        return _erc20Released;
    }

    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    function release() public virtual {
        if (block.timestamp < _start) {
            revert("VestingWallet: not started");
        }
        uint256 amount = releasable();
        if (!_released) {
            _released = true;
        }
        if (amount > IERC20(token).balanceOf(address(this))) {
            amount = IERC20(token).balanceOf(address(this));
        }
        _erc20Released += amount;
        emit ERC20Released(token, amount);
        IERC20(token).transfer(beneficiary(), amount);
    }

    function vestedAmount(uint64 timestamp)
        public
        view
        virtual
        returns (uint256)
    {

        if (timestamp < start()) {
            return 0;
        }

        uint256 amnt;
        if (!_released) {
            amnt =
                (IERC20(token).balanceOf(address(this)) * _startPercent) /
                100;
        }

        uint64 cycles = (timestamp - start()) / duration();
        return
            ((cycles *
                ((IERC20(token).balanceOf(address(this)) + released()) *
                    _cyclePercent)) / 100) + amnt;
    }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/IUniswapV2Router02.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint8);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IVesting {
    function release() external;

    function releasable() external view returns (uint256);
}

interface Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

contract PreSale {
    event SaleStart(
        uint256 startTime,
        uint256 endTime,
        uint256 rate,
        uint256 amount
    );

    event TokenSale(address buyer, uint256 amount);

    struct Sale {
        bool whitelist;
        uint256 rate;
        uint256 amount;
        uint64 startTime;
        uint64 endTime;
        address owner;
        uint256 minVal;
        uint256 maxVal;
        uint256 softCap;
        uint256 hardCap;
    }

    struct AutoDex {
        bool enabled;
        uint256 rate;
        uint8 liquidity;
        uint64 lockUpTime;
    }

    Sale public sale;
    AutoDex public autoDex;
    address public token;
    bytes32 private merkleRoot;
    address public immutable factoryContract;
    address private vestingContract;
    uint8 private immutable decimals;
    bool private softCapReached = false;
    bool private liquidityExecuted = false;
    bool private vesting = false;
    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    Factory public factory =
        Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    constructor(address _token) {
        token = _token;
        decimals = IERC20(_token).decimals();
        factoryContract = msg.sender;
    }

    function createPreSale(
        bool _whitelist,
        address _token,
        uint256 _rate,
        uint256 _amount,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _minVal,
        uint256 _maxVal,
        uint64 _startTime,
        uint64 _endTime,
        address _owner
    ) public returns (bool) {
        require(msg.sender == factoryContract);
        require(_token != address(0));
        require(_rate > 0);
        require(_amount > 0);
        require(
            _startTime < _endTime && _endTime > block.timestamp,
            "PreSale: invalid time"
        );

        sale = Sale(
            _whitelist,
            _rate,
            _amount,
            _startTime,
            _endTime,
            _owner,
            _minVal,
            _maxVal,
            _softCap,
            _hardCap
        );
        emit SaleStart(_startTime, _endTime, _rate, _amount);
        return true;
    }

    function buyTokens(bytes32[] calldata _merkleProof) external payable {
        require(
            block.timestamp >= sale.startTime &&
                block.timestamp <= sale.endTime,
            "PreSale: sale is not active"
        );
        require(
            msg.value <= sale.maxVal && msg.value >= sale.minVal,
            "PreSale: amount is not in range"
        );
        uint256 amount = (msg.value * sale.rate) / 10**(18 - decimals);
        if (sale.whitelist) {
            require(checkWhitelist(_merkleProof, msg.sender), "Not whitelisted");
        }
        require(msg.value + address(this).balance <= sale.hardCap, "Hard cap");
        if (address(this).balance >= sale.softCap) {
            softCapReached = true;
        }

        if (vesting) {
            if (IERC20(token).balanceOf(address(this)) < amount) {
                uint256 toRelease = IVesting(vestingContract).releasable();
                require(
                    IERC20(token).balanceOf(address(this)) + toRelease >=
                        amount,
                    "Not enough tokens"
                );
                IVesting(vestingContract).release();
            }
        }
        require(
            IERC20(token).transfer(msg.sender, amount),
            "PreSale: transfer failed"
        );
        emit TokenSale(msg.sender, amount);
    }

    function checkWhitelist(bytes32[] calldata _merkleProof,address _adr)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_adr))));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function withdrawToken() external {
        require(msg.sender == sale.owner, "PreSale: not owner");
        require(sale.endTime < block.timestamp, "PreSale: sale is active");
        require(autoDex.enabled == false || liquidityExecuted == true);
        if (vesting) {
            IVesting(vestingContract).release();
        }
        require(
            IERC20(token).transfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            ),
            "PreSale: transfer failed"
        );
    }

    function withdrawETH() external {
        require(sale.endTime < block.timestamp, "PreSale: sale is active");
        require(softCapReached == false, "PreSale: soft cap reached");
        uint256 val = IERC20(token).balanceOf(msg.sender);
        require(
            IERC20(token).transferFrom(
                msg.sender,
                sale.owner,
                IERC20(token).balanceOf(msg.sender)
            ),
            "PreSale: transfer failed"
        );
        (bool sent, ) = payable(msg.sender).call{
            value: ((val * 10**(18 - decimals)) / sale.rate)
        }("");
        require(sent, "PreSale: withdraw failed");
    }

    function editRoot(bytes32 _merkleRoot) external {
        require(msg.sender == sale.owner, "PreSale: not owner");
        merkleRoot = _merkleRoot;
    }

    function setWhitelist(bool _whitelist) external {
        require(msg.sender == sale.owner, "PreSale: not owner");
        sale.whitelist = _whitelist;
    }

    receive() external payable {}

    function addLiquidity() external payable {
        require(msg.sender == sale.owner, "PreSale: not owner");
        require(sale.endTime < block.timestamp, "PreSale: sale is active");
        require(softCapReached == true, "PreSale: soft cap not reached");
        require(autoDex.enabled == true, "PreSale: autoDex is disabled");
        uint256 amount = (autoDex.rate *
            ((autoDex.liquidity * address(this).balance) / 100)) /
            10**(18 - decimals);
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "PreSale: not enough tokens"
        );
        require(
            IERC20(token).approve(
                address(uniswapV2Router),
                IERC20(token).balanceOf(address(this))
            ),
            "PreSale: approve failed"
        );
        uniswapV2Router.addLiquidityETH{
            value: (autoDex.liquidity * address(this).balance) / 100
        }(token, amount, 0, 0, address(this), block.timestamp + 1000);
        autoDex.lockUpTime = uint64(block.timestamp + autoDex.lockUpTime);
        payable(sale.owner).transfer(address(this).balance);
        liquidityExecuted = true;
    }

    function withdrawLiquidity() external {
        require(msg.sender == sale.owner, "PreSale: not owner");
        require(autoDex.lockUpTime < block.timestamp, "PreSale: lock up time");
        address pair = factory.getPair(token, uniswapV2Router.WETH());
        require(pair != address(0), "PreSale: pair not found");
        IERC20(pair).transfer(
            sale.owner,
            IERC20(pair).balanceOf(address(this))
        );
    }

    function Dex(
        bool _enabled,
        uint256 _dexRate,
        uint8 _liquidity,
        uint64 _lockUpTime
    ) external {
        require(msg.sender == factoryContract, "PreSale: not factory contract");
        require(_enabled == true, "cannot unset dex");
        autoDex = AutoDex(_enabled, _dexRate, _liquidity, _lockUpTime);
    }

    function withdrawOwner() external {
        require(msg.sender == sale.owner, "PreSale: not owner");
        require(sale.endTime < block.timestamp, "PreSale: sale is active");
        require(autoDex.enabled == false, "PreSale: autoDex is enabled");
        require(softCapReached == true, "PreSale: soft cap reached");
        payable(sale.owner).transfer(address(this).balance);
    }

    function setVesting(address _vestingContract) external {
        require(msg.sender == factoryContract, "PreSale: not factory contract");
        vesting = true;
        vestingContract = _vestingContract;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
}