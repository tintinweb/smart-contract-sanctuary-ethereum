/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

interface IStaking {
    struct SingleNft {
        uint256 tokenId;
        uint256 amount;
    }
    // ApeCoin logic
    function depositSelfApeCoin(uint256 _amount) external;
    function withdrawSelfApeCoin(uint256 _amount) external;
    function claimSelfApeCoin() external;
    // BAYC logic
    function depositBAYC(SingleNft[] memory _nfts) external;
    function claimSelfBAYC(uint256[] memory _nfts) external;
    function withdrawBAYC(SingleNft[] memory _nfts, address _recipient) external;
    // MAYC logic
    function depositMAYC(SingleNft[] memory _nfts) external;
    function claimSelfMAYC(uint256[] memory _nfts) external;
    function withdrawMAYC(SingleNft[] memory _nfts, address _recipient) external;
    function nftPosition(uint256 _poolId, uint256 _tokenId) external view returns (uint256, uint256);
    function stakedTotal(address _address) external view returns (uint256);
    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

interface IERC721 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function approve(address to, uint256 tokenId) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) external;

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) external;

  function safeTransferFrom(address from, address to, uint256 tokenId) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

abstract contract IERC4626 is IERC20{

    function asset() external view virtual returns (address asset);

    function totalAssets() external view virtual returns (uint256 totalAssets);

    function deposit(uint256 assets, address receiver) external virtual returns (uint256 shares);

    function mint(uint256 shares, address receiver) external virtual returns (uint256 assets);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual returns (uint256 assets);

    function convertToShares(uint256 assets) external view virtual returns (uint256 shares);

    function convertToAssets(uint256 shares) external view virtual returns (uint256 assets);

    function maxDeposit(address owner) external view virtual returns (uint256 maxAssets);

    function previewDeposit(uint256 assets) external view virtual returns (uint256 shares);

    function maxMint(address owner) external view virtual returns (uint256 maxShares);

    function previewMint(uint256 shares) external view virtual returns (uint256 assets);

    function maxWithdraw(address owner) external view virtual returns (uint256 maxAssets);

    function previewWithdraw(uint256 assets) external view virtual returns (uint256 shares);

    function maxRedeem(address owner) external view virtual returns (uint256 maxShares);

    function previewRedeem(uint256 shares) external view virtual returns (uint256 assets);
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

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
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

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
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @title NFT Receiver
/// @author Tessera
/// @notice Plugin contract for handling receipts of non-fungible tokens
contract NFTReceiver is ERC721TokenReceiver {
    /// @notice Handles the receipt of a single ERC721 token
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract StakedNFTs is Owned, NFTReceiver {

    IStaking public immutable staking;
    IERC20 public immutable apecoin;
    IERC721 public immutable bayc;
    IERC721 public immutable mayc;
    IERC4626 public immutable stakedApecoin;

    uint256 public constant UNIT = 1e18;
    uint256 public maxBaycApe = 10094000000000000000000;
    uint256 public maxMaycApe = 2042000000000000000000;

    mapping(uint256 => address) public stakedBaycTokenOwners;
    mapping(uint256 => address) public stakedMaycTokenOwners;

    constructor(address _apecoin, address _stakedApecoin, address _bayc, address _mayc, address _staking) Owned(msg.sender){
        apecoin = IERC20(_apecoin);
        bayc = IERC721(_bayc);
        mayc = IERC721(_mayc);
        stakedApecoin = IERC4626(_stakedApecoin);
        staking = IStaking(_staking);
        apecoin.approve(_staking, type(uint256).max);
        apecoin.approve(_stakedApecoin, type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function depositBayc(IStaking.SingleNft[] memory _nfts) public {
        for (uint256 x = 0; x < _nfts.length; x++) {
            uint256 tokenId = _nfts[x].tokenId;
            bayc.transferFrom(msg.sender, address(this), tokenId);
            apecoin.transferFrom(msg.sender, address(this), _nfts[x].amount);
            stakedBaycTokenOwners[tokenId] = msg.sender;
        }
        staking.depositBAYC(_nfts);
    }

    function depositMayc(IStaking.SingleNft[] memory _nfts) public {
        for (uint256 x = 0; x < _nfts.length; x++) {
            uint256 tokenId = _nfts[x].tokenId;
            mayc.transferFrom(msg.sender, address(this), tokenId);
            apecoin.transferFrom(msg.sender, address(this), _nfts[x].amount);
            stakedMaycTokenOwners[tokenId] = msg.sender;
        }
        staking.depositMAYC(_nfts);
    }

    function withdrawBayc(IStaking.SingleNft[] memory _nfts) public {
        staking.withdrawBAYC(_nfts, msg.sender);
        for (uint256 x = 0; x < _nfts.length; x++) {
            uint256 tokenId = _nfts[x].tokenId;
            require(stakedBaycTokenOwners[tokenId] == msg.sender, "NOT_OWNER");
            bayc.transferFrom(address(this), msg.sender, tokenId);
            stakedBaycTokenOwners[tokenId] = address(0);
        }
    }

    function withdrawMayc(IStaking.SingleNft[] memory _nfts) public {
        staking.withdrawMAYC(_nfts, msg.sender);
        for (uint256 x = 0; x < _nfts.length; x++) {
            uint256 tokenId = _nfts[x].tokenId;
            require(stakedMaycTokenOwners[tokenId] == msg.sender, "NOT_OWNER");
            mayc.transferFrom(address(this), msg.sender, tokenId);
            stakedMaycTokenOwners[tokenId] = address(0);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        CLAIM & RESTAKE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim and restake ApeCoin
    /// @dev we will max out our available ApeCoin balance
    /// if we are already maxed out we deposit into StakedApecoin
    /// @param _nft array of NFTs to claim
    function claimBayc(uint256[] memory _nft) public {
        uint256[] memory nft = new uint256[](1);
        for (uint256 x = 0; x < _nft.length; x++) {
            nft[0] = _nft[x];
            staking.claimSelfBAYC(nft);
            uint256 balance = apecoin.balanceOf(address(this));
            (uint256 staked,) = staking.nftPosition(1, nft[0]);
            uint256 missing = maxBaycApe - staked;
            if (missing > 0) {
                uint256 toDeposit = missing > balance ? balance : missing;
                IStaking.SingleNft[] memory deposit = new IStaking.SingleNft[](1);
                deposit[0].tokenId = nft[0];
                deposit[0].amount = toDeposit;
                staking.depositBAYC(deposit);
                balance = apecoin.balanceOf(address(this));
            }
            stakedApecoin.deposit(balance, stakedBaycTokenOwners[nft[0]]);
        }
    }

}