/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
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
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
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

// File: contracts/plague.sol




pragma solidity ^0.8.9;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline) external payable returns (uint[] memory amounts);
}

contract TESTPlague is ERC20, Ownable {
    string private _name = "test";
    string private _symbol = "test";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 100000000 * 10**_decimals;

    uint256 public _maxWalletSize = (_totalSupply * 40) / 1000; // 3% 

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isWalletLimitExempt;

    // Fee receiver
    uint256 public DevFeeBuy = 40;
    uint256 public DevFeeSell = 40;
    uint256 public InfecterFeeBuy = 40;
    uint256 public InfecterFeeSell = 40;


    uint256 public TotalBase = DevFeeBuy + DevFeeSell + InfecterFeeBuy + InfecterFeeSell;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public autoLiquidityReceiver;
    address public MarketingWallet;

    IUniswapV2Router02 public router;
    address public pair;

    bool public isTradingEnabled = false;

    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply / 1000) * 3; // 0.3%

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping (address => bool) public infected;
    mapping (address => address) public infecter;
    mapping (address => uint256) public totalRewards;
    mapping (address => uint256) public pendingRewards;
    mapping (address => uint256) public amountOfInfection;

    uint256 currentPendingRewards;

    uint256 public totalAllRewards;
    uint256 public amountOfAllInfection;

    address[5] bestInfector;

    uint256 launchTime;

    event infection(address indexed infecter, address indexed infected);
    event _claim(address indexed user, uint256 amount);
    event _claimPresale(address indexed user, uint256 amount);
    event _depositETH(address indexed user, uint256 amount);

    constructor(address _MarketingWallet) Ownable(){
        router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); //sushiswap
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        MarketingWallet = _MarketingWallet;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[MarketingWallet] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[MarketingWallet] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506] = true; //sushiswap

        infected[msg.sender] = true;
        infected[MarketingWallet] = true;
        infected[DEAD] = true;
        infected[address(this)] = true;
        infected[pair] = true;
        infected[0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506] = true; //sushiswap
        

        _balances[msg.sender] = _totalSupply * 100 / 100;

        emit Transfer(address(0), msg.sender, _totalSupply * 100 / 100);
    }
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
    receive() external payable { }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    function setMaxWallet(uint256 _maxWalletSize_) external onlyOwner {
        require(
            _maxWalletSize_ >= _totalSupply / 1000,
            "Can't set MaxWallet below 0.1%"
        );
        _maxWalletSize = _maxWalletSize_;
    }


    function setFeesWallet(address _MarketingWallet) external onlyOwner {
        MarketingWallet = _MarketingWallet;
        isFeeExempt[MarketingWallet] = true;

        isWalletLimitExempt[MarketingWallet] = true;        
    }

    function setIsWalletLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isWalletLimitExempt[holder] = exempt; // Exempt from max wallet
    }

    function setSwapEnabled(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function infect(address _toInfect) external {
        require(!infected[_toInfect], "Already infected");
        require(balanceOf(msg.sender) >= 1, "not enough tokens to infect");
        require(infected[msg.sender] == true, "not infected");

        infecter[_toInfect] = msg.sender;
        infected[_toInfect] = true;
        amountOfInfection[msg.sender] ++;
        amountOfAllInfection ++;
        
        _balances[msg.sender] = _balances[msg.sender] - 1 ether;
        bool temp;
        temp = _basicTransfer(msg.sender, _toInfect, 1 ether);

        emit infection(msg.sender, _toInfect);
    }

    function infectOG(address[] memory _toInfect) external onlyOwner{

        for(uint256 i; i < _toInfect.length; i++) {
            require(!infected[_toInfect[i]], "Already infected");
            require(balanceOf(msg.sender) >= 1, "not enough tokens to infect");
            require(infected[msg.sender] == true, "not infected");

            infecter[_toInfect[i]] = msg.sender;
            infected[_toInfect[i]] = true;
            amountOfInfection[msg.sender] ++;
            amountOfAllInfection ++;

            
            _balances[msg.sender] = _balances[msg.sender] - 1 ether;
            bool temp;
            temp = _basicTransfer(msg.sender, _toInfect[i], 1 ether);

            emit infection(msg.sender, _toInfect[i]);
        }
    }

    function checkBestInfector() internal {
        address user = msg.sender;
        uint256[5] memory rewards;
        address[5] memory sortedAddresses;
        uint256 index = 0;
        for (uint i = 0; i < bestInfector.length; i++) {
            rewards[i] = totalRewards[bestInfector[i]];
        }

        for (uint256 i = 0; i < bestInfector.length; i++) {
            if(bestInfector[i] == user) {
                index = i;
            }
        }

        if(rewards[0] < totalRewards[user] && index != bestInfector.length - 1) {
            if(index == 0) sortedAddresses[0] = user;
            for (uint256 i = index + 1; i < bestInfector.length; i++) {
                if(rewards[i] < totalRewards[user]) {
                    sortedAddresses[i - 1] = bestInfector[i];
                    sortedAddresses[i] = user;
                }
            }
            bestInfector = sortedAddresses;
        }
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(isFeeExempt[sender] || isFeeExempt[recipient] || isTradingEnabled, "Not authorized to trade yet");

        // Checks infection
        if(recipient != pair) {
            require(infected[recipient], "Not infected");
        }

        
        // Checks max transaction limit
        if (sender != owner() && recipient != owner() && recipient != DEAD) {
            if(recipient != pair) {
            require(isWalletLimitExempt[recipient] || (_balances[recipient] + amount <= _maxWalletSize), "Transfer amount exceeds the MaxWallet size.");
            }
        }
        //shouldSwapBack
        if (shouldSwapBack() && recipient == pair) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - amount;

        //Check if should Take Fee
        uint256 amountReceived = (!shouldTakeFee(sender) ||
            !shouldTakeFee(recipient))
            ? amount
            : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeTeam = 0;
        uint256 feeInfecter = 0;
        uint256 feeAmount = 0;

        if (sender == pair && recipient != pair) {
            // <=> buy
            feeTeam = amount * DevFeeBuy / 1000;
            feeInfecter = amount * InfecterFeeBuy / 1000;
            pendingRewards[infecter[recipient]] += feeInfecter;
            currentPendingRewards += feeInfecter;
        }
        if (sender != pair && recipient == pair) {
            // <=> sell
            feeTeam = amount * DevFeeSell / 1000;
            feeInfecter = amount * InfecterFeeSell / 1000;
            pendingRewards[infecter[sender]] += feeInfecter; 
            currentPendingRewards += feeInfecter;
        }
        feeAmount = feeTeam + feeInfecter;

        if (feeAmount > 0) {
            _balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }
        
        return amount - feeAmount;
    }

    function claim() external {
        require(msg.sender == tx.origin, "error");
        require(pendingRewards[msg.sender] > 0 ,"no pending rewards");

        uint256 _pendingRewards = pendingRewards[msg.sender];
        pendingRewards[msg.sender] = 0;
        
        _balances[address(this)] = _balances[address(this)] - _pendingRewards;
        bool temp;
        temp = _basicTransfer(address(this), msg.sender, _pendingRewards);
        require(temp, "transfer failed");
        totalRewards[msg.sender] += _pendingRewards;
        totalAllRewards += _pendingRewards;
        currentPendingRewards -= _pendingRewards;

        checkBestInfector();
        emit _claim(msg.sender, _pendingRewards);
    }

    function getBestInfector() external view returns(address[5] memory) { return bestInfector;}

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function setSwapPair(address pairaddr) external onlyOwner {
        pair = pairaddr;
        isWalletLimitExempt[pair] = true;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount >= 1, "Can't set SwapThreshold to ZERO");
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

     function setIsTradingEnabled(bool _isTradingEnabled) external onlyOwner{
        isTradingEnabled = _isTradingEnabled;
        if(isTradingEnabled) launchTime = block.timestamp;
    }

    function checkBestInfector(address user) internal {
        uint256[5] memory rewards;// Tableau de récompenses en attente pour chaque adresse dans bestInfector
        address[5] memory sortedAddresses; // Tableau trié des adresses
        uint256 index;
        for (uint i = 0; i < bestInfector.length; i++) {
            rewards[i] = totalRewards[bestInfector[i]];
        }

        for (uint256 i = 0; i < 5; i++) {
                if(bestInfector[0] == user) {
                    index = i;
                }
            }

        if(rewards[0] < totalRewards[user]) {
            if(index > 0) sortedAddresses[0] = user;
            for (index; index < 5; index++) {
                if(rewards[index] < totalRewards[user]) {
                    sortedAddresses[index - 1] = bestInfector[index];
                    sortedAddresses[index] = user;
                }
            }
        }

        bestInfector = sortedAddresses;
    }

    function setFees(uint256 _DevFeeBuy, uint256 _DevFeeSell, uint256 _InfecterFeeBuy, uint256 _InfecterFeeSell) external onlyOwner {
        DevFeeBuy = _DevFeeBuy;
        DevFeeSell = _DevFeeSell;
        InfecterFeeBuy = _InfecterFeeBuy;
        InfecterFeeSell = _InfecterFeeSell;
        TotalBase = DevFeeBuy + DevFeeSell + InfecterFeeBuy + InfecterFeeSell;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = balanceOf(address(this)) - currentPendingRewards;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp + 5 minutes
        );

        uint256 amountETHDev = address(this).balance;

        if(amountETHDev>0){
            bool tmpSuccess;
            (tmpSuccess,) = payable(MarketingWallet).call{value: amountETHDev, gas: 30000}("");
        }
    }

    ///////////////////////PRESALE////////////////////////////////

    mapping(address => uint256) public amountDeposit;
    mapping(uint256 => mapping(address => bool)) public haveClaimedPresale; // to controle if user has claimed or not regarding the step

    uint256 public MinimumPresaleAllocation = 0.03 ether;
    uint256 public MaximumPresaleAllocation = 0.2 ether;
    uint256 public presaleTotal;
    uint256 public TotalPresaleAllocation;
    uint256[] public vesting = [40, 30, 30];
    uint256 public presalePercentage = 46;
    bool public beforeSale;
    uint256 delayBetweenClaimPresale = 86400;
    bytes32 merkleRoot;
    
    bool public saleOpen;

    function openSale() external onlyOwner {
        saleOpen = true;
    }

    function closeSale() external onlyOwner {
        saleOpen = false;
        beforeSale = true;
    }

    function changeBeforeSale(bool _beforeSale) external onlyOwner {
        beforeSale = _beforeSale;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getCurrentStep() public view returns(uint256){
        if (launchTime == 0) return 0;
        if (launchTime + delayBetweenClaimPresale > block.timestamp) return 1;
        if (launchTime + 2 * delayBetweenClaimPresale > block.timestamp) return 2;
        return 3;
    }

    function setDelayBetweenClaimPresale(uint256 _delayBetweenClaimPresale) external onlyOwner{
        delayBetweenClaimPresale = _delayBetweenClaimPresale;
    }

    function depositETH(bytes32[] calldata _proof) external payable {
        require(msg.sender == tx.origin, "error");
        require(saleOpen, "sale is not open");
        require(msg.value + amountDeposit[msg.sender] >= MinimumPresaleAllocation, "Amount deposit is too low.");
        require(msg.value + amountDeposit[msg.sender] <= MaximumPresaleAllocation, "Amount deposit is too high.");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");

        amountDeposit[msg.sender] += msg.value;
        presaleTotal += msg.value;
        infected[msg.sender] = true;
        emit _depositETH(msg.sender, msg.value);
    }


    function checkCanClaimPresale(address user) view public returns(bool){
        return amountDeposit[user] > 0 && getCurrentStep() != 0
        && !haveClaimedPresale[getCurrentStep()][user];
    }

    function getAmountToClaim(address user) view public returns(uint256) {
        uint256 percentage;
        uint256 amount;
        for(uint256 i = 1; i <= getCurrentStep(); i++) {
            if(!haveClaimedPresale[i][user]) {
                percentage = vesting[i - 1];
                amount += (amountDeposit[user] * (_totalSupply * presalePercentage / 100) / presaleTotal) * percentage / 100;
            }
        }
        return amount;
    }

    function claimPresale() external {
        require(checkCanClaimPresale(msg.sender), "cant claim presale");
        require(msg.sender == tx.origin, "not allowed");
        uint256 amount;
        uint256 percentage;

        for(uint256 i = 1; i <= getCurrentStep(); i++) {
            if(!haveClaimedPresale[i][msg.sender]) {
                percentage = vesting[i - 1];
                amount += (amountDeposit[msg.sender] * (_totalSupply * presalePercentage / 100) / presaleTotal) * percentage / 100;
            }
            haveClaimedPresale[i][msg.sender] = true;
        }
        _balances[msg.sender] += amount;
        _balances[address(this)] -= amount;
        emit Transfer(address(this), msg.sender, amount);
        emit _claimPresale(msg.sender, amount);
    }

    //Whitelist
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof)
        public
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

}