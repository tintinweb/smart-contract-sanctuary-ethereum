/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// File: interfaces/IBottoStaking.sol


pragma solidity 0.8.11;

interface IBottoStaking {
    function botto() external view returns (address);
    function owner() external view returns (address);
    function totalStaked() external view returns (uint256);
    function userStakes(address user) external view returns (uint256);
}

// File: interfaces/IERC20.sol


pragma solidity 0.8.11;

/// @title ERC20 Interface
/// @dev https://eips.ethereum.org/EIPS/eip-20
/// @author Andreas Bigger <[email protected]>
interface IERC20 {
    /// @dev The circulating supply of tokens
    function totalSupply() external view returns (uint256);

    /// @dev The number of tokens owned by the account
    /// @param account The address to get the balance for
    function balanceOf(address account) external view returns (uint256);

    /// @dev Transfers the specified amount of tokens to the recipient from the sender
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @dev The amount of tokens the spender is permitted to transfer from the owner
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Permits a spender to transfer an amount of tokens
    function approve(address spender, uint256 amount) external returns (bool);

    /// @dev Transfers tokens from the sender using the caller's allowance
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev Emitted when tokens are transfered
    /// @param from The address that is sending the tokens
    /// @param to The token recipient
    /// @param value The number of tokens
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when an owner permits a spender
    /// @param owner The token owner
    /// @param spender The permitted spender
    /// @param value The number of tokens
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @rari-capital/solmate/src/tokens/ERC721.sol


pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: TuringKey.sol


pragma solidity ^0.8.11;





/// @notice Too few tokens remain
error InsufficientTokensRemain();

/// @notice Balance of sender is or would be over token limit per holder
// @param balance Token balance
// @param limit Token limit per holder
error SenderBalanceOverTokenLimit(uint256 balance, uint8 limit);

/// @notice Not enough ether sent to mint
/// @param cost The minimum amount of ether required to mint
/// @param sent The amount of ether sent to this contract
error InsufficientFunds(uint256 cost, uint256 sent);

/// @notice Supply send to update is lower than the current mints count
/// @param supply Amount sent to update
/// @param tokenCount Current minst amount
error SupplyLowerThanTokenCount(uint256 supply, uint256 tokenCount);

/// @notice Supply send to update is lower than the current mints count
/// @param supply Amount sent to update
/// @param absoluteMaximumTokens hardcoded maximum number of tokens
error SupplyHigherThanAbsoluteMaximumTokens(uint256 supply, uint256 absoluteMaximumTokens);

/// @notice Account trying to mint the token is not a botto staker
/// @param user account sending the transaction
error UserIsNotAStaker(address user);


/// @title Turing Key
/// @author GoldmanDAO
/// @dev Note that mint price and Token URI are updateable
contract TuringKey is ERC721, Ownable {
    /// @dev BottoStaking contract
    IBottoStaking private bottoStaking;

    ///  @dev amount of time when the contract is going to be locked
    uint256 public timelock; 

    /// @dev Base URI
    string private internalTokenURI;

    /// @dev Number of tokens
    uint256 public tokenCount;

    /// @notice Limit of tokens per holder
    uint8 public constant HOLDER_TOKEN_LIMIT = 10;

    /// @notice The maximum number of nfts to mint, not updateable
    uint256 public constant ABSOLUTE_MAXIMUM_TOKENS = 969;

    /// @notice The actual supply of nfts. Can be updated by the owner
    uint256 public currentSupply = 200;

    /// @notice Cost to mint a token
    uint256 public publicSalePrice = 0.5 ether;

    //////////////////////////////////////////////////
    //                  MODIFIER                    //
    //////////////////////////////////////////////////

    /// @dev Checks mint requirements
    /// -> Mint in time or pre-release authorized sender
    /// -> Enough supply
    /// -> Balance of target address in limits
    /// -> Value sended matches price
    modifier canMint(address to, uint8 amount) {
        if (block.timestamp < timelock) {
            if(bottoStaking.userStakes(msg.sender) == 0 || bottoStaking.userStakes(to) == 0) {
                revert UserIsNotAStaker(msg.sender);
            }
        }
        if (tokenCount + amount >= currentSupply) {
            revert InsufficientTokensRemain();
        }
        if (balanceOf[to] + amount > HOLDER_TOKEN_LIMIT) {
            revert SenderBalanceOverTokenLimit(balanceOf[to] + amount, HOLDER_TOKEN_LIMIT);
        }
        if (publicSalePrice * amount > msg.value) {
            revert InsufficientFunds(publicSalePrice * amount, msg.value);
        }
        _;
    }

    //////////////////////////////////////////////////
    //                 CONSTRUCTOR                  //
    //////////////////////////////////////////////////

    /// @dev Sets the ERC721 Metadata and OpenSea Proxy Registry Address
    constructor(string memory _tokenURI, IBottoStaking _bottoStaking) ERC721("Turing Key", "TKEY") {
      internalTokenURI = _tokenURI;
      bottoStaking = _bottoStaking;
      timelock = block.timestamp + 2 days;
    }

    //////////////////////////////////////////////////
    //                  METADATA                    //
    //////////////////////////////////////////////////

    /// @dev Returns the URI for the given token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return internalTokenURI;
    }

    /////////////////////////////////////////////////
    //                MINTING LOGIC                 //
    //////////////////////////////////////////////////

    /// @notice Mint one or more tokens
    /// @param to whom the token is being sent to
    /// @param amount the amount of tokens to mint
    function mint(address to, uint8 amount)
        public
        virtual
        payable
        canMint(to, amount) 
    {
        for (uint8 i=0; i < amount; i++) {
            tokenCount++;
            _mint(to, tokenCount);
        }
    }

    /// @notice Safe mint one or mont tokens
    /// @param to whom the token is being sent to
    /// @param amount the amount of tokens to mint
    function safeMint(address to, uint8 amount)
        public
        virtual
        payable
        canMint(to, amount)
    {
        for (uint8 i=0; i < amount; i++) {
            tokenCount++;
            _safeMint(to, tokenCount);
        }
    }

    /// @notice Safe mint a token
    /// @param to whom the token is being sent to
    /// @param data needed for the contract to be call
    function safeMint(
        address to,
        uint8 amount,
        bytes memory data
    )
        public
        virtual
        payable
        canMint(to, amount)
    {
        for (uint8 i=0; i < amount; i++) {
            tokenCount++;
            _safeMint(to, tokenCount, data);
        }
    }

     //////////////////////////////////////////////////
    //                BURNING LOGIC                 //
    //////////////////////////////////////////////////

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    //////////////////////////////////////////////////
    //                 ADMIN LOGIC                  //
    //////////////////////////////////////////////////

    /// @notice Sets the tokenURI for the membership
    function setInternalTokenURI(string memory _internalTokenURI) external onlyOwner {
        internalTokenURI = _internalTokenURI;
    }

    /// @dev Allows the owner to update the amount of memberships to be minted
    function updateCurrentSupply(uint256 _supply) public onlyOwner {
        if (_supply > ABSOLUTE_MAXIMUM_TOKENS) {
            revert SupplyHigherThanAbsoluteMaximumTokens(_supply, ABSOLUTE_MAXIMUM_TOKENS);
        } 
        if (_supply < tokenCount) {
            revert SupplyLowerThanTokenCount(_supply, tokenCount);
        }
        currentSupply = _supply;
    }

    /// @dev Allows the owner to change the prize of the membership 
    function setPublicSalePrice(uint256 _publicSalePrice) public onlyOwner {
      publicSalePrice = _publicSalePrice;
    }

    /// @dev Allows the owner to withdraw eth
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @dev Allows the owner to withdraw any erc20 tokens sent to this contract
    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    //////////////////////////////////////////////////
    //                 ROYALTIES                    //
    //////////////////////////////////////////////////
    // @dev Support for EIP 2981 Interface by overriding erc165 supportsInterface
    // function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    //     return
    //         interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
    //         interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
    //         interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
    //         interfaceId == 0x2a55205a;  // ERC165 Interface ID for ERC2981
    // }

    /// @dev Royalter information
    // function royaltyInfo(uint256 tokenId, uint256 salePrice)
    //     external
    //     view
    //     returns (address receiver, uint256 royaltyAmount)
    // {
    //     receiver = address(this);
    //     royaltyAmount = (salePrice * 5) / 100;
    // }
}