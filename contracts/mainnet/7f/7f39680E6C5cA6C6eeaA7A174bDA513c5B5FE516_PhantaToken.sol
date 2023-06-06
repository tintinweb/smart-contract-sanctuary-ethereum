// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    PhantaToken
      - $PHANTA is a passive income solution featured with HoldFarm, LP-Incentives, Deflationary, Referral, Anti-Bot, etc.
      - The bearish market makes passive income even sweeter.

    Website:  https://www.phanta.club/
    Twitter:  https://twitter.com/phantatoken_eth
    Telegram: https://t.me/phantaclub

**/

import "./IERC20.sol";
import "./IUniswapV2Factory.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
}

library MerkleProof {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    // Sorted Pair Hash
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}

contract PhantaToken is Ownable, IERC20 {
    string constant public override name = "Phanta Club";
    string constant public override symbol = "PHANTA";
    uint8 constant public override decimals = 3;
    uint256 immutable public override totalSupply;

    mapping(address => mapping(address => uint256)) public override allowance;

    // DIVIDEND: WE Redesigned Dividend, Less Gas Used.
    mapping(address => uint256) private _balanceOf;
    uint8 private _decimals = 11;
    uint256 private _dividendSupply;

    // Uni-v2 LP
    address public lp;

    // ANTI-BOT: ATTENTION! WE KILL FIRST 3 BLOCK BUYERS!
    uint256 public startBlock = 0;
    mapping(address => bool) public banned;

    // ANTI-WHALE: REAL FAIR LAUNCH! Buy Limits At First 100 BLOCKs.
    uint256 public maxBuyingAmount = 10000000 * 10 ** decimals;
    uint256 public maxHoldingAmount = 52000000 * 10 ** decimals;

    // Your Referer & Rewards
    mapping(address => address) public refererOf;
    mapping(address => uint256) public rewards;

    // AIRDROP: for phantabear holders
    bytes32 immutable public mRoot;
    mapping(address => bool) public claimed;

    constructor(uint256 supply, bytes32 merkleroot){
    	totalSupply = supply * 10 ** decimals;

        // DIVIDEND
        _balanceOf[msg.sender] = 100 * 10 ** _decimals;
        _dividendSupply = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        // Mainnet: Uniswap Router & WETH
        IUniswapV2Router01 swapRouter = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        lp = IUniswapV2Factory(swapRouter.factory()).createPair(address(this), weth);

        // AIRDROP: merkle tree
        mRoot = merkleroot;
    }

    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);

        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function balanceOf(address account) public view override returns (uint256){
        return p2a(_balanceOf[account]);
    }

    function p2a(uint256 p) private view returns (uint256) {
        return p * _dividendSupply / 100 / 10 ** _decimals ;
    }

    function a2p(uint256 a) private view returns (uint256) {
        return (a * 100 * 10 ** _decimals) / _dividendSupply;
    }

    // Uniswap Spender: 0x000000000022d473030f116ddee9f6b43ac78ba3
    function _approve( address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from the zero address");

        // ANTI-BOT: ATTENTION! WE KILL FIRST THREE BLOCK BUYERS!
        require(!banned[from] && !banned[to], "Banned Account");

        // check balance
        uint256 p = a2p(amount);
        require(_balanceOf[from] >= p, "ERC20: transfer amount exceeds balance");

        bool tax = false;
        if (from == lp || to == lp) {
            if (startBlock == 0) {// Trading starting...
                startBlock = block.number;
            } else if (startBlock >= block.number - 3) {// ANTI-BOT
                tax = true;
                if (to != lp) {
                    banned[to] = true;
                }
            } else if (startBlock >= block.number - 100) {// Fair Launch, DNOT BUY TOO MUCH
                tax = true;
                if (from == lp) { // Buy Order
                    require((amount <= maxBuyingAmount) && (balanceOf(to) + amount <= maxHoldingAmount), "Anti-WHALE: Plese Buy Later." );
                }
            } else {
                tax = true;
            }

        }

        // Token Transfer
        _balanceOf[from] -= p;
        if (tax) {
            uint256 p_dividend = p / 100;
            uint256 a_dividend = amount / 100;

            p -= p_dividend * 2;
            amount -= a_dividend * 2;

            // Dividend for holders
            _balanceOf[address(0)] += p_dividend;
            _dividendSupply += a_dividend;
            emit Transfer(from, address(0), a_dividend);

            // Dividend for LP or referer
            address referer = (refererOf[from] == address(0)) ? refererOf[to] : refererOf[from];
            if (referer != address(0)) {
                _balanceOf[referer] += p_dividend;
                rewards[referer] += a_dividend;
                emit Transfer(from, referer, a_dividend);
            } else {
                _balanceOf[lp] += p_dividend;
                emit Transfer(from, lp, a_dividend);
            }
            
        }
        _balanceOf[to] += p;
        emit Transfer(from, to, amount);
    }

    // Referral Program
    function activate(address referer) external returns (bool) {
        require(referer != msg.sender, "Referer cannot be yourself.");
        require(refererOf[msg.sender] == address(0), "You had set referer already.");
        refererOf[msg.sender] = referer;
        return true;
    }

    // AIRDROP to PHANTABEAR holders
    function claim(uint16 amount, bytes32[] memory proof) external returns (bool res) {
        address account = msg.sender;
        require(!claimed[account], "This Account had claimed already.");

        // calculate leaf & verify
        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        require(MerkleProof.verify(proof, mRoot, leaf), "Proof not Passed.");

        // 10000 Tokens per NFT
        _transfer(address(this), account, uint256(amount) * 10000 * 10 ** decimals);
        claimed[account] = true;
        return true;
    }

}