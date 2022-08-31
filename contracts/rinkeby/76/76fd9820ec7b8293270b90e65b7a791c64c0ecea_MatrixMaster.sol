/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// File: Utils.sol



pragma solidity ^0.8.0;

/// @notice 管理者権限の実装
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not owner");
        _;
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = _newOwner;
    }
}

/// @notice 発行権限の実装
abstract contract Mintable {
    mapping(address => bool) public minters;

    constructor() {
        minters[msg.sender] = true;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Mintable: caller is not minter");
        _;
    }

    function setMinter(address newMinter, bool mintable) public virtual onlyMinter {
        require(
            newMinter != address(0),
            "Mintable: new minter is the zero address"
        );
        minters[newMinter] = mintable;
    }
}

/// @notice 焼却権限の実装
abstract contract Burnable {
    mapping(address => bool) public burners;

    constructor() {
        burners[msg.sender] = true;
    }

    modifier onlyBurner() {
        require(burners[msg.sender], "Burnable: caller is not burner");
        _;
    }

    function setBurner(address newBurner, bool burnable) public virtual onlyBurner {
        require(
            newBurner != address(0),
            "Burnable: new burner is the zero address"
        );
        burners[newBurner] = burnable;
    }
}

/// @notice 署名の実装
abstract contract SupportSig {

    function getSigner(bytes memory contents, bytes memory sig) internal pure returns (address) {
        bytes32 hash_ = keccak256(contents);
        return _recover(hash_, sig);
    }

    function _recover(bytes32 hash_, bytes memory sig) private pure returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash_, v, r, s);
        }
    }
}

/// @notice トークン更新履歴の実装
abstract contract SupportTokenUpdateHistory {

    struct  TokenUpdateHistoryItem {
        uint256 tokenId;
        uint256 updatedAt;
    }

    uint256 public tokenUpdateHistoryCount;
    TokenUpdateHistoryItem[] public tokenUpdateHistory;

    constructor() {
        TokenUpdateHistoryItem memory dummy;
        tokenUpdateHistory.push(dummy);  // 1-based index
    }

    function onTokenUpdated(uint256 tokenId) internal {
        tokenUpdateHistory.push(TokenUpdateHistoryItem(tokenId, block.timestamp));
        tokenUpdateHistoryCount++;
    }
}
// File: IMatrix.sol



pragma solidity ^0.8.0;

interface IMatrix {
    /// @notice Eggを生成する。
    function spawn(string calldata metadataHash, address to) external returns (uint256);

    /// @notice Eggの生成に必要とするAnimaの量を取得する。
    function getPrice() external view returns (uint256);
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: MatrixMater.sol



pragma solidity ^0.8.0;





contract MatrixMaster is Ownable {

    IERC20 public animaToken;
    uint256 public numRegistered;
    mapping(uint256 => address) public registered;
    mapping(address => uint256) public lookup;
    mapping(address => bool) public isClient;

    event Register(uint256 matrixId, address contractAddress);
    event Spawn(uint256 matrixId, uint256 eggId, address to, uint256 price);

    function setAnimaToken(address tokenAddress) external onlyOwner
    {
        animaToken = IERC20(tokenAddress);
    }

    function setClient(address account, bool flag) external onlyOwner
    {
        isClient[account] = flag;
    }

    modifier onlyClientOrOwner() {
        require(
            isClient[msg.sender] || (Ownable.owner == msg.sender),
            "MatrixMaster: caller is not client nor owner"
        );
        _;
    }

    /// @notice Matrixを登録する。
    function register(address contractAddress) external returns (uint256)
    {
        require(
            IERC165(contractAddress).supportsInterface(type(IMatrix).interfaceId),
            "MatrixMaster: not Matrix implementation"
        );
        require(
            lookup[contractAddress] == 0,
            "MatrixMaster: duplicates not allowed"
        );
        uint256 id = numRegistered + 1;
        registered[id] = contractAddress;
        lookup[contractAddress] = id;
        emit Register(id, contractAddress);
        numRegistered++;
        return id;
    }

    /// @notice 貯まったAnimaを引き出す（暫定）
    function withdraw(address to) external onlyOwner {
        uint256 amount = animaToken.balanceOf(address(this));
        animaToken.transfer(to, amount);
    }

    /// @notice Egg生成に要するAnimaの額を取得する。
    function getPrice(uint256 matrixId) external view returns (uint256) {
        require(registered[matrixId] != address(0x0), "MatrixMaster: invalid matrixId");
        IMatrix imatrix = IMatrix(registered[matrixId]);
        return imatrix.getPrice();
    }

    /// @notice Eggを生成する。
    function spawn(uint256 matrixId, string calldata metadataHash, address to) external onlyClientOrOwner returns (uint256) {
        require(registered[matrixId] != address(0x0), "MatrixMaster: invalid matrixId");
        IMatrix matrix = IMatrix(registered[matrixId]);
        uint256 price = matrix.getPrice();
        animaToken.transferFrom(msg.sender, address(this), price);
        uint256 eggId = matrix.spawn(metadataHash, to);
        emit Spawn(matrixId, eggId, to, price);
        return eggId;
    }
}