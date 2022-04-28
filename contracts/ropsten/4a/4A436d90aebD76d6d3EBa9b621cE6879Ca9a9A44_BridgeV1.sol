/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity ^0.8.0;

library BridgeLibraryV1 {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

interface IUniswapV2 {
    struct Pair {
        address token0;
        address token1;
    }

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BridgeV1 {
    uint256 public molecule = 1;
    uint256 public denominator = 1000;
    bool isInit = false;
    bool lock = false;
    uint256 public committeeNum = 0;
    address public EthAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address owner;
    /// @dev Minimum token transfer quantity
    uint256 minAmount = 1;
    bytes private salt = "v1.0";
    mapping(address => address) public uniswapPair;
    mapping(address => IUniswapV2.Pair) public uniswapTokens;
    mapping(address => bool) public accountLockout;
    // mapping(address => bool) public assetTable;
    mapping(address => uint256) public account;
    mapping(address => mapping(uint256 => Asset)) public assetPipeline;
    mapping(address => uint256) public accountNonce;
    mapping(uint256 => bool) public network;

    /// @dev Token transfer event
    /// @param from is  Token sender address, which is the standard Ethereum network account address
    /// @param amount is  Number of token transfers
    /// @param networkid network
    /// @param nonce is accout nonce
    /// @param blockNumber is  Block number of the current event
    /// @param fromAsset is  The standard erc20 address that needs to be transferred out is transferred from Ethereum network to dfinity network
    /// @param toAsset is Dfinity network target Token address
    /// @param to is The token needs to be transferred to the wallet account of dfinity network
    event Deposit(
        address from,
        uint256 amount,
        uint256 networkid,
        uint256 nonce,
        uint256 blockNumber,
        address fromAsset,
        string toAsset,
        string to
    );


    struct Asset {
        string token;
        string symbol;
        uint256 decimal;
        bool exist;
    }

    modifier Sender() {
        require(
            !BridgeLibraryV1.isContract(msg.sender),
            "Contract not supported"
        );
        _;
    }

    modifier Lock() {
        require(!lock, "locking");
        lock = true;
        _;
        lock = false;
    }



    function addNetWork(uint256 networkid) public {
        network[networkid] = true;
    }

    function addAsset(
        uint256 networkid,
        address erc20,
        Asset memory asset
    ) public {
        require(
            network[networkid],
            "The network does not support asset transfer"
        );
        assetPipeline[erc20][networkid] = asset;
    }

    /// @dev Transfer etheum main network token eth, which will flow from etheum to dfinity network through bridge network
    /// @param wallet is the destination wallet address of the other network
    function depositEth(uint256 networkid, string memory wallet)
        public
        payable
        Sender
    {
        require(
            assetPipeline[EthAddress][networkid].exist,
            "No longer on balance sheet"
        );
        uint256 fee = getFee(msg.value);
        require(fee > 0, "fee not enough");
        uint256 surplus = msg.value - fee;
        require(msg.value > minAmount, "Too little deposit");
        uint256 nonce = increaseNonce(msg.sender);
        emit Deposit(
            msg.sender,
            surplus,
            networkid,
            nonce,
            block.number,
            EthAddress,
            assetPipeline[EthAddress][networkid].token,
            wallet
        );
    }

    /// @dev Transfer the standard erc20 token on Ethereum to the dfinity network
    /// @param _erc20token is Erc20 token address to be transferred
    /// @param _amount is Number of erc20 tokens to be transferred
    /// @param wallet is the destination wallet address of the other network
    function depositErc20Token(
        IERC20 _erc20token,
        uint256 networkid,
        uint256 _amount,
        string memory wallet
    ) public Sender {
        require(
            assetPipeline[address(_erc20token)][networkid].exist,
            "No longer on balance sheet"
        );

        uint256 fee = getFee(_amount);
        require(fee > 0, "fee not enough");
        uint256 surplus = _amount - fee;

        require(
            _erc20token.transferFrom(msg.sender, address(this), _amount),
            "TransferFrom failed"
        );
        uint256 nonce = increaseNonce(msg.sender);
        emit Deposit(
            msg.sender,
            surplus,
            networkid,
            nonce,
            block.number,
            address(_erc20token),
            assetPipeline[address(_erc20token)][networkid].token,
            wallet
        );
    }

    function increaseNonce(address ethaccount) internal returns (uint256) {
        accountNonce[ethaccount] = accountNonce[ethaccount] + 1;
        return accountNonce[ethaccount];
    }

    function getAccountNonce(address ethaccount) public view returns (uint256) {
        return accountNonce[ethaccount];
    }

    function getFee(uint256 value) public view returns (uint256) {
        return (value * molecule) / denominator;
    }
}