// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title Promise.Monster (P.M)
/// @author parseb.eth
/// @notice promise and reputation building support structure
/// @dev Experimental. Do not use.
/// @custom:security contact: [email protected]

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "delegatable-sol/Delegatable.sol";
import "delegatable-sol/TypesAndDecoders.sol";

//import "aave-v3-core/contracts/interfaces/.... .sol"

struct Promise {
    Standing state;
    /// lifecycle state
    uint256 liableID;
    /// liable soul
    address claimOwner;
    /// creditor
    uint256[2] times;
    /// executable within timeframe [starting with | until].
    SignedDelegation delegation;
    /// signed delegation
    bytes callData;
}
/// encoded function call() data

struct Asset {
    uint256 howMuch;
    /// type 2: (NFT) id of token | type 1: (ERC20)
    address tokenAddress;
    uint8 assetType;
}

enum Standing {
    Uninitialized,
    Created,
    Honored,
    Broken,
    Expired
}

contract PromiseMonster is ERC721("Promise.Monster", unicode"👾"), Delegatable("Promise.Monster", "1") {
    address public AAVE;
    address deployer;
    uint256 public globalID;

    /// @notice promise function allowlist
    mapping(bytes4 => bool) caveat;

    /// @notice stores IDs for address' relevant promises [historical]
    /// first item is reserved for soulbinding token
    mapping(address => uint256[]) public hasOrIsPromised;

    /// @notice stores the address of a claim
    mapping(uint256 => Promise) getPromise;

    /// @notice moral responsibility
    /// issuer and all liable are responsible for the existence of the debt
    /// pull transfer pattern only for indebted souls
    mapping(uint256 => address[]) chainedSouls;
    /// @dev might not be needed since record and association is present in hasOrIsPromised;

    /// @notice registers asset bearing token
    mapping(uint256 => Asset) assetToken;

    mapping(address => uint[]) assetIDS;

    /*//////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {
        AAVE = address(bytes20("placeholder"));
        globalID = 11;
        _caveatInit();
        deployer = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                        Errors
    //////////////////////////////////////////////////////////////*/

    error Blasphemy();
    error UnpassableBuck();
    error SoullessMachine();
    error Unreachable();

    /*//////////////////////////////////////////////////////////////
                        Events
    //////////////////////////////////////////////////////////////*/

    event IDincremented();
    event NewSoulAcquired(address indexed who, uint256 indexed soulID);
    event BurdenTransfer(uint256 indexed claim, uint256 indexed destinationSoul);
    event AssetTokenCreated(address contractAsset, uint256 quantity, address assetOwner);
    event MintedPromise(address indebted, address honored, uint256 tokenID);
    event BrokenPromise(uint256 pID);
    event KeptPromise(uint256 pID);

    /*//////////////////////////////////////////////////////////////
                        Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @notice modifier checks the sender has
    modifier isSoul() {
        require(getSoulID(msg.sender) != 0, "unreppenting soul");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        Public
    //////////////////////////////////////////////////////////////*/

    /// @notice permantently registers sender as indebtness capable soul
    function mintSoul() public returns (uint256) {
        if (!_isEOA()) {
            revert SoullessMachine();
            /// @dev contracts might have souls. don't know yet.
        }
        require(hasOrIsPromised[msg.sender].length == 0 || hasOrIsPromised[msg.sender][0] == 0, "already owned");
        _incrementID();
        if (globalID % 2 == 0) {
            _incrementID();
        }
        //hasOrIsPromised[msg.sender][0] == globalID;
        _mint(msg.sender, globalID);
        hasOrIsPromised[msg.sender][0] == globalID;  /// @dev reversing order + transfer. duplication and multiple sb mint (confirmed)
                                                    /// @dev see https://goerli.etherscan.io/token/0x790813e2c96874d4200Fe9B63a92E771839A8254?a=13#readContract
                                                    /// address 0xBD1302Ce69e65cAA2c85bB686A27437EaE00C6Fd has multiple uneaven ids on getPIDS
        emit NewSoulAcquired(msg.sender, globalID); /// 0,14,16,22,24,26,41,43,45 - 3 sbs minted in a row
                                                    /// retunrn in beforeTransfer... that would be and interesting kind of stupid
        return globalID;
    }

    /*//////////////////////////////////////////////////////////////
                        External
    //////////////////////////////////////////////////////////////*/

    /// @notice wraps any ERC20 or ERC721 assets in a Promise Monster ERC721 token
    /// @param contract_ address of the token contract
    /// @param howmuch_ quantity of ERC20 or ERC721 token ID
    function makeAsset(address contract_, uint8 assetType, uint256 howmuch_, address to_) external returns (bool s) {
        globalID = incrementIDAsset();
        ///@dev noticed potential promise/2 and asset/10 id override. untested
        ///@dev  require(contract_ != address(this), 'Matryoshkas not allowed'); /// @dev what would be the point?
        if (to_ == address(0)) {
            to_ = _msgSender();
        }
        assetToken[globalID].tokenAddress = contract_;
        assetToken[globalID].assetType = assetType;
        assetToken[globalID].howMuch = howmuch_;
        assetIDS[to_].push(globalID);

        uint256 balance;

        if (assetType == 1) {
            balance = IERC20(contract_).balanceOf(address(this));
            s = IERC20(contract_).transferFrom(_msgSender(), address(this), howmuch_);
            /// how much ERC20
            if (s) {
                s = (balance + howmuch_ <= IERC20(contract_).balanceOf(address(this)));
            }
        }
        if (assetType == 2) {
            balance = IERC721(contract_).balanceOf(address(this));
            IERC721(contract_).transferFrom(_msgSender(), address(this), howmuch_);
            /// tokenID ERC721
            s = (balance < IERC721(contract_).balanceOf(address(this)));
        }
        require(s, "Failed to register asset");
        _mint(to_, globalID);

        emit AssetTokenCreated(contract_, howmuch_, to_);
    }

    /// @notice burns asset token, transfers underlying to specified address or sender
    /// @param assetID_: ID of token
    /// @param to_: address to transfer the underlying to. if 0x0 new ower will be _msgSender();
    function burnAsset(uint256 assetID_, address to_) external returns (bool s) {
        require(ownerOf(assetID_) == msg.sender || msg.sender == address(this), "Unauthorized");

        if (to_ == address(0)) {
            to_ = _msgSender();
        }
        Asset memory A = assetToken[assetID_];
        if (A.assetType == 1) {
            s = IERC20(A.tokenAddress).transfer(to_, A.howMuch);
        }
        if (!s) {
            IERC721(A.tokenAddress).transferFrom(address(this), to_, A.howMuch);
            s = IERC721(A.tokenAddress).ownerOf(A.howMuch) != address(this);
        }
        require(s, "Failed to Burn Asset");
        delete assetToken[assetID_];
        _burn(assetID_);
    }

    // function mintPromisedView(address logicContract, bytes calldata call_) external returns (bool s) {
    //     require(address(logicContract).code.length > 1, 'Not a contract');
    //     (s,) = logicContract.call(call_);
    // }

    /// @notice mints promise
    /// @param to_: who is being promised
    /// @param delegation_: what is being delegated / promised
    function mintPromise(
        SignedDelegation memory delegation_,
        address to_,
        bytes memory callData_,
        uint256[2] memory times_
    )
        external
        isSoul
        returns (uint256 pID)
    {
        address liable = verifyDelegationSignature(delegation_);
        require(to_ == delegation_.delegation.delegate, "to_ is not delegated");
        require(msg.sender == liable, "not your signed delegation");
        require(!caveat[bytes4(callData_)], "unreachable function");
        //// @dev ?promise resubmission check

        Promise memory newP;

        newP.state = Standing.Created;
        newP.liableID = getSoulID(liable);
        newP.claimOwner = to_;
        newP.delegation = delegation_;
        newP.callData = callData_;
        uint start = block.timestamp + times_[0];
        newP.times = [start, start + times_[1]];

        pID = _incrementID();
        if (pID % 10 == 0) {
            pID += 1;
        }
        if (pID % 2 != 0) {
            pID += 1;
        }
        /// @dev
        globalID = pID;

        if (hasOrIsPromised[to_].length == 0) {
            hasOrIsPromised[to_].push(0);
        }
        hasOrIsPromised[to_].push(pID);
        hasOrIsPromised[liable].push(pID);

        getPromise[pID] = newP;

        _mint(to_, pID);

        emit MintedPromise(msg.sender, to_, pID);
    }

    /// @notice executes a promise. sender needs to be the claim owner or delegated
    /// @param promiseID: identifier of promise to execute
    function executePromise(uint256 promiseID) external returns (bool s) {
        Promise memory P;
        P = getPromise[promiseID];

        require(P.state == Standing.Created);
        if (P.times[0] > block.timestamp) revert("soon");
        
        require(msg.sender == P.claimOwner || msg.sender == P.delegation.delegation.delegate, "Not promised to you"); ///@dev case - promise is transfered: delegate can still execute. assign on transfer & &&
        if (P.times[1] < block.timestamp) {
            P.state = Standing.Expired;
            return false;
        }

        delete getPromise[promiseID].delegation;

        (s,) = address(this).call(P.callData);
        if (s) {
            P.state = Standing.Honored;
            emit KeptPromise(promiseID);
        } else {
            P.state = Standing.Broken;
            // revert("FFF");
            emit BrokenPromise(promiseID);
        }

        // _tricklePromiseEndState(promiseID); /// @dev promise transfer chained- alters reputation accross ownership. Advanced feature. later.
        _burn(promiseID);

        /// @dev sufficient replay protection ?
    }

    /*//////////////////////////////////////////////////////////////
                        private
    //////////////////////////////////////////////////////////////*/

    /// @notice increments global ID
    function _incrementID() private returns (uint256) {
        unchecked {
            ++globalID;
        }
        emit IDincremented();
        return globalID;
    }

    function incrementIDAsset() private returns (uint256 gid_) {
        gid_ = globalID + (10 - (globalID % 10));
    }
    //// @notice checks if sender is EOA

    function _isEOA() private view returns (bool) {
        return (msg.sender == tx.origin);
    }

    /// @notice trickles promise state if liability transfered. @dev might lead to duplicates
    function _tricklePromiseEndState(uint256 promiseID_) private {
        uint256 i;
        for (; i < chainedSouls[promiseID_].length;) {
            hasOrIsPromised[chainedSouls[promiseID_][i]].push(promiseID_);
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                         View
    //////////////////////////////////////////////////////////////*/

    function getSoulID(address eoa_) public view returns (uint256 id) {
        id = hasOrIsPromised[eoa_].length == 0 ? 0 : hasOrIsPromised[eoa_][0];
    }

    function getPromiseByID(uint256 id_) public view returns (Promise memory P) {
        P = getPromise[id_];
    }


    //// 
    function assetsOf(address who_) external view returns (uint256[] memory) {
        return assetIDS[who_];
        // uint256[] memory pids = hasOrIsPromised[who_];
        // Asset[] memory A = new Asset[](pids.length);
        // /// @dev
        // uint256 i = 1;
        // uint256 c;
        // for (; i < pids.length;) {
        //     if (pids[i] % 10 == 0 && ownerOf(pids[i]) == who_) {
        //         A[i] = assetToken[pids[i]];
        //         unchecked {
        //             ++c;
        //         }
        //         pids[i] = 0;
        //     }
        //     unchecked {
        //         ++i;
        //     }
        // }

        // X = new Asset[](c);
        // for (; i < pids.length;) {
        //     if (pids[i] != 0) {
        //         X[c] = (assetToken[i]);
        //         unchecked {
        //             --c;
        //         }
        //     }
        //     unchecked {
        //         --i;
        //     }
        // }
    }

    function getAssetByID(uint256 id_) external view returns (Asset memory A) {
        A = assetToken[id_];
    }

    function getPIDS(address ofWho_) external view returns (uint256[] memory) {
        return hasOrIsPromised[ofWho_];
    }

    function getPromiseHistory(address who_) public view returns (Promise[] memory) {
        uint256 x = hasOrIsPromised[who_].length;

        Promise[] memory P;
        if (x < 2) {
            return P;
        }
        P = new Promise[](x);
        uint256 i = 1;
        for (; i < x;) {
            if (hasOrIsPromised[who_][i] == 0) {
                continue;
            }
            P[i] = getPromiseByID(hasOrIsPromised[who_][i]);
            unchecked {
                ++i;
            }
        }
        return P;
    }

    /// @notice  returns two arrays of Promises (liabilities, assets)
    /// @param who_: for  what address to return associated promises
    function getLiabilitiesAssetsFor(address who_) external view returns (Promise[] memory Pl, Promise[] memory Pa) {
        Pl = getPromiseHistory(who_);
        uint256 len = Pl.length;
        Pa = new  Promise[](len);
        uint256 i;
        for (; i < len;) {
            if (Pl[i].claimOwner == who_) {
                Pa[i] = Pl[i];
                delete Pl[i];
            }
            unchecked {
                ++i;
            }
        }
        return (Pl, Pa);
    }

    function getSoulRecord() public view {}

    /*//////////////////////////////////////////////////////////////
                        Override
    //////////////////////////////////////////////////////////////*/

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        if (tokenId % 10 == 0) {
            return;
        } // token is asset

        if (from == address(0)) {
            hasOrIsPromised[msg.sender].push(tokenId); /// @dev this is bad - to && msg.sender diverge
            return;
        }
        if (tokenId % 2 == 0) {
            /// not soulbound
            /// liability transfer possible only through pull pattern

            if (getSoulID(msg.sender) == getPromise[tokenId].liableID) {
                revert UnpassableBuck();
            }

            if (getPromise[tokenId].claimOwner == msg.sender) {
                getPromise[tokenId].claimOwner = to;
                return;
            }
            /// mints soul if none
            /// @dev @note contract might gain soul
            uint256 toSoul = getSoulID(to) == 0 ? mintSoul() : getSoulID(to);
            /// liable for promise
            getPromise[tokenId].liableID = globalID;
            /// shared moral responsibility
            chainedSouls[tokenId].push(msg.sender);
            /// @dev potential trickle state duplication
            /// add claimed burden to soul
            hasOrIsPromised[msg.sender].push(tokenId);

            emit BurdenTransfer(tokenId, toSoul);
        } else {
            /// soulbound
            revert Blasphemy();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        Misc
    //////////////////////////////////////////////////////////////*/

    function _msgSender() internal view override (Context, DelegatableCore) returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
            if (caveat[bytes4(msg.data[0:4])]) {
                revert Unreachable();
            }
        } else {
            sender = msg.sender;
        }

        return sender;
    }

    function _caveatInit() private {
        caveat[this.mintSoul.selector] = true;
        caveat[this.mintPromise.selector] = true;
        caveat[this.getSoulID.selector] = true;
        caveat[this.getPromiseHistory.selector] = true;
        caveat[this.getSoulRecord.selector] = true;
        caveat[this.approve.selector] = true;
        caveat[this.setApprovalForAll.selector] = true;
        caveat[this.transferFrom.selector] = true;
        ///
        caveat[0x42842e0e] = true;
        caveat[0xb88d4fde] = true;
    }

    /*//////////////////////////////////////////////////////////////
                        Only deployer
    //////////////////////////////////////////////////////////////*/

    /// @notice adds, removes or flips caveats
    /// @param sig: 4 byte signature of function to allow/dissalow list
    function flipCaveat(bytes4 sig) external returns (bool) {
        require(msg.sender == deployer);
        caveat[sig] = !caveat[sig];
        return caveat[sig];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// import "hardhat/console.sol";
import {EIP712DOMAIN_TYPEHASH} from "./TypesAndDecoders.sol";
import {Delegation, Invocation, Invocations, SignedInvocation, SignedDelegation} from "./CaveatEnforcer.sol";
import {DelegatableCore} from "./DelegatableCore.sol";
import {IDelegatable} from "./interfaces/IDelegatable.sol";

abstract contract Delegatable is IDelegatable, DelegatableCore {
    /// @notice The hash of the domain separator used in the EIP712 domain hash.
    bytes32 public immutable domainHash;

    /**
     * @notice Delegatable Constructor
     * @param contractName string - The name of the contract
     * @param version string - The version of the contract
     */
    constructor(string memory contractName, string memory version) {
        domainHash = getEIP712DomainHash(
            contractName,
            version,
            block.chainid,
            address(this)
        );
    }

    /* ===================================================================================== */
    /* External Functions                                                                    */
    /* ===================================================================================== */

    /// @inheritdoc IDelegatable
    function getDelegationTypedDataHash(Delegation memory delegation)
        public
        view
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                GET_DELEGATION_PACKETHASH(delegation)
            )
        );
        return digest;
    }

    /// @inheritdoc IDelegatable
    function getInvocationsTypedDataHash(Invocations memory invocations)
        public
        view
        returns (bytes32)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainHash,
                GET_INVOCATIONS_PACKETHASH(invocations)
            )
        );
        return digest;
    }

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) public pure returns (bytes32) {
        bytes memory encoded = abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(contractName)),
            keccak256(bytes(version)),
            chainId,
            verifyingContract
        );
        return keccak256(encoded);
    }

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        public
        view
        virtual
        override(IDelegatable, DelegatableCore)
        returns (address)
    {
        Delegation memory delegation = signedDelegation.delegation;
        bytes32 sigHash = getDelegationTypedDataHash(delegation);
        address recoveredSignatureSigner = recover(
            sigHash,
            signedDelegation.signature
        );
        return recoveredSignatureSigner;
    }

    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        public
        view
        returns (address)
    {
        bytes32 sigHash = getInvocationsTypedDataHash(
            signedInvocation.invocations
        );
        address recoveredSignatureSigner = recover(
            sigHash,
            signedInvocation.signature
        );
        return recoveredSignatureSigner;
    }

    // --------------------------------------
    // WRITES
    // --------------------------------------

    /// @inheritdoc IDelegatable
    function contractInvoke(Invocation[] calldata batch)
        external
        override
        returns (bool)
    {
        return _invoke(batch, msg.sender);
    }

    /// @inheritdoc IDelegatable
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        override
        returns (bool success)
    {
        uint i;
        for (;i < signedInvocations.length;) {  /// @dev ;lol;
            SignedInvocation calldata signedInvocation = signedInvocations[i];
            address invocationSigner = verifyInvocationSignature(
                signedInvocation
            );
            _enforceReplayProtection(
                invocationSigner,
                signedInvocations[i].invocations.replayProtection
            );

            success = i == 0 ?
 _invoke(signedInvocation.invocations.batch, invocationSigner) : success && _invoke(signedInvocation.invocations.batch, invocationSigner);
        
        unchecked { ++ i;}
        }

        
    }

    /* ===================================================================================== */
    /* Internal Functions                                                                    */
    /* ===================================================================================== */
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "./libraries/ECRecovery.sol";

// BEGIN EIP712 AUTOGENERATED SETUP
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

struct Invocation {
    Transaction transaction;
    SignedDelegation[] authority;
}

bytes32 constant INVOCATION_TYPEHASH = keccak256(
    "Invocation(Transaction transaction,SignedDelegation[] authority)Delegation(address delegate,bytes32 authority)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Invocations {
    Invocation[] batch;
    ReplayProtection replayProtection;
}

bytes32 constant INVOCATIONS_TYPEHASH = keccak256(
    "Invocations(Invocation[] batch,ReplayProtection replayProtection)Delegation(address delegate,bytes32 authority)Invocation(Transaction transaction,SignedDelegation[] authority)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct SignedInvocation {
    Invocations invocations;
    bytes signature;
}

bytes32 constant SIGNEDINVOCATION_TYPEHASH = keccak256(
    "SignedInvocation(Invocations invocations,bytes signature)Delegation(address delegate,bytes32 authority)Invocation(Transaction transaction,SignedDelegation[] authority)Invocations(Invocation[] batch,ReplayProtection replayProtection)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)"
);

struct Transaction {
    address to;
    uint256 gasLimit;
    bytes data;
}

bytes32 constant TRANSACTION_TYPEHASH = keccak256(
    "Transaction(address to,uint256 gasLimit,bytes data)"
);

struct ReplayProtection {
    uint256 nonce;
    uint256 queue;
}

bytes32 constant REPLAYPROTECTION_TYPEHASH = keccak256(
    "ReplayProtection(uint nonce,uint queue)"
);

struct Delegation {
    address delegate;
    bytes32 authority;
    // string[] caveats;
}

bytes32 constant DELEGATION_TYPEHASH = keccak256(
    "Delegation(address delegate,bytes32 authority)"
);

// struct Caveat {
//     address enforcer;
//     bytes terms;
// }

// bytes32 constant CAVEAT_TYPEHASH = keccak256(
//     ""
// );

struct SignedDelegation {
    Delegation delegation;
    bytes signature;
}

bytes32 constant SIGNEDDELEGATION_TYPEHASH = keccak256(
    "SignedDelegation(Delegation delegation,bytes signature)Delegation(address delegate,bytes32 authority)"
);

// END EIP712 AUTOGENERATED SETUP

contract EIP712Decoder is ECRecovery {
    // BEGIN EIP712 AUTOGENERATED BODY. See scripts/typesToCode.js

    // function GET_EIP712DOMAIN_PACKETHASH(EIP712Domain memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         EIP712DOMAIN_TYPEHASH,
    //         _input.name,
    //         _input.version,
    //         _input.chainId,
    //         _input.verifyingContract
    //     );

    //     return keccak256(encoded);
    // }

    function GET_INVOCATION_PACKETHASH(Invocation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            INVOCATION_TYPEHASH,
            GET_TRANSACTION_PACKETHASH(_input.transaction),
            GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(_input.authority)
        );

        return keccak256(encoded);
    }

    function GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(
        SignedDelegation[] memory _input
    ) public pure returns (bytes32) {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(
                encoded,
                GET_SIGNEDDELEGATION_PACKETHASH(_input[i])
            );
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    function GET_INVOCATIONS_PACKETHASH(Invocations memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            INVOCATIONS_TYPEHASH,
            GET_INVOCATION_ARRAY_PACKETHASH(_input.batch),
            GET_REPLAYPROTECTION_PACKETHASH(_input.replayProtection)
        );

        return keccak256(encoded);
    }

    function GET_INVOCATION_ARRAY_PACKETHASH(Invocation[] memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded;
        for (uint256 i = 0; i < _input.length; i++) {
            encoded = bytes.concat(
                encoded,
                GET_INVOCATION_PACKETHASH(_input[i])
            );
        }

        bytes32 hash = keccak256(encoded);
        return hash;
    }

    // function GET_SIGNEDINVOCATION_PACKETHASH(SignedInvocation memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         SIGNEDINVOCATION_TYPEHASH,
    //         GET_INVOCATIONS_PACKETHASH(_input.invocations),
    //         keccak256(_input.signature)
    //     );

    //     return keccak256(encoded);
    // }

    function GET_TRANSACTION_PACKETHASH(Transaction memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            TRANSACTION_TYPEHASH,
            _input.to,
            _input.gasLimit,
            keccak256(_input.data)
        );

        return keccak256(encoded);
    }

    function GET_REPLAYPROTECTION_PACKETHASH(ReplayProtection memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            REPLAYPROTECTION_TYPEHASH,
            _input.nonce,
            _input.queue
        );

        return keccak256(encoded);
    }

    function GET_DELEGATION_PACKETHASH(Delegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            DELEGATION_TYPEHASH,
            _input.delegate,
            _input.authority
            // GET_CAVEAT_ARRAY_PACKETHASH(_input.caveats)
        );

        return keccak256(encoded);
    }

    // function GET_CAVEAT_ARRAY_PACKETHASH(Caveat[] memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded;
    //     for (uint256 i = 0; i < _input.length; i++) {
    //         encoded = bytes.concat(encoded, GET_CAVEAT_PACKETHASH(_input[i]));
    //     }

    //     bytes32 hash = keccak256(encoded);
    //     return hash;
    // }

    // function GET_CAVEAT_PACKETHASH(Caveat memory _input)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes memory encoded = abi.encode(
    //         CAVEAT_TYPEHASH,
    //         _input.enforcer,
    //         keccak256(_input.terms)
    //     );

    //     return keccak256(encoded);
    // }

    function GET_SIGNEDDELEGATION_PACKETHASH(SignedDelegation memory _input)
        public
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(
            SIGNEDDELEGATION_TYPEHASH,
            GET_DELEGATION_PACKETHASH(_input.delegation),
            keccak256(_input.signature)
        );

        return keccak256(encoded);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 1;

            // compute log10(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 10**64) {
                valueCopy /= 10**64;
                length += 64;
            }
            if (valueCopy >= 10**32) {
                valueCopy /= 10**32;
                length += 32;
            }
            if (valueCopy >= 10**16) {
                valueCopy /= 10**16;
                length += 16;
            }
            if (valueCopy >= 10**8) {
                valueCopy /= 10**8;
                length += 8;
            }
            if (valueCopy >= 10**4) {
                valueCopy /= 10**4;
                length += 4;
            }
            if (valueCopy >= 10**2) {
                valueCopy /= 10**2;
                length += 2;
            }
            if (valueCopy >= 10**1) {
                length += 1;
            }
            // now, length is log10(value) + 1

            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 1;

            // compute log256(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 1 << 128) {
                valueCopy >>= 128;
                length += 16;
            }
            if (valueCopy >= 1 << 64) {
                valueCopy >>= 64;
                length += 8;
            }
            if (valueCopy >= 1 << 32) {
                valueCopy >>= 32;
                length += 4;
            }
            if (valueCopy >= 1 << 16) {
                valueCopy >>= 16;
                length += 2;
            }
            if (valueCopy >= 1 << 8) {
                valueCopy >>= 8;
                length += 1;
            }
            // now, length is log256(value) + 1

            return toHexString(value, length);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./TypesAndDecoders.sol";

// abstract contract CaveatEnforcer {
//     function enforceCaveat(
//         bytes calldata terms,
//         Transaction calldata tx,
//         bytes32 delegationHash
//     ) public virtual returns (bool);
// }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// import {EIP712Decoder, EIP712DOMAIN_TYPEHASH} from "./TypesAndDecoders.sol";
// import {Delegation, Invocation, Invocations, SignedInvocation, SignedDelegation, Transaction, ReplayProtection, CaveatEnforcer} from "./CaveatEnforcer.sol";
import "./TypesAndDecoders.sol";

abstract contract DelegatableCore is EIP712Decoder {
    /// @notice Account delegation nonce manager
    mapping(address => mapping(uint256 => uint256)) internal multiNonce;

    function getNonce(address intendedSender, uint256 queue)
        external
        view
        returns (uint256)
    {
        return multiNonce[intendedSender][queue];
    }

    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        public
        view
        virtual
        returns (address);

    function _enforceReplayProtection(
        address intendedSender,
        ReplayProtection memory protection
    ) internal {
        uint256 queue = protection.queue;
        uint256 nonce = protection.nonce;
        require(
            nonce == (multiNonce[intendedSender][queue] + 1),
            "DelegatableCore:nonce2-out-of-order"
        );
        multiNonce[intendedSender][queue] = nonce;
    }

    function _execute(
        address to,
        bytes memory data,
        uint256 gasLimit,
        address sender
    ) internal returns (bool success) {
        bytes memory full = abi.encodePacked(data, sender);
        assembly {
            success := call(gasLimit, to, 0, add(full, 0x20), mload(full), 0, 0)
        }
    }

    function _invoke(Invocation[] calldata batch, address sender)
        internal
        returns (bool success)
    {
        for (uint256 x = 0; x < batch.length; x++) {
            Invocation memory invocation = batch[x];
            address intendedSender;
            address canGrant;

            // If there are no delegations, this invocation comes from the signer
            if (invocation.authority.length == 0) {
                intendedSender = sender;
                canGrant = intendedSender;
            }

            bytes32 authHash = 0x0;

            for (uint256 d = 0; d < invocation.authority.length; d++) {
                SignedDelegation memory signedDelegation = invocation.authority[
                    d
                ];
                address delegationSigner = verifyDelegationSignature(
                    signedDelegation
                );

                // Implied sending account is the signer of the first delegation
                if (d == 0) {
                    intendedSender = delegationSigner;
                    canGrant = intendedSender;
                }

                require(
                    delegationSigner == canGrant,
                    "DelegatableCore:invalid-delegation-signer"
                );

                Delegation memory delegation = signedDelegation.delegation;
                require(
                    delegation.authority == authHash,
                    "DelegatableCore:invalid-authority-delegation-link"
                );

                // TODO: maybe delegations should have replay protection, at least a nonce (non order dependent),
                // otherwise once it's revoked, you can't give the exact same permission again.
                bytes32 delegationHash = GET_SIGNEDDELEGATION_PACKETHASH(
                    signedDelegation
                );

                // Each delegation can include any number of caveats.
                // A caveat is any condition that may reject a proposed transaction.
                // The caveats specify an external contract that is passed the proposed tx,
                // As well as some extra terms that are used to parameterize the enforcer.
                // for (uint16 y = 0; y < delegation.caveats.length; y++) {
                //     CaveatEnforcer enforcer = CaveatEnforcer(
                //         delegation.caveats[y].enforcer
                //     );
                //     bool caveatSuccess = enforcer.enforceCaveat(
                //         delegation.caveats[y].terms,
                //         invocation.transaction,
                //         delegationHash
                //     );
                //     require(caveatSuccess, "DelegatableCore:caveat-rejected");
                // }

                // Store the hash of this delegation in `authHash`
                // That way the next delegation can be verified against it.
                authHash = delegationHash;
                canGrant = delegation.delegate;
            }

            // Here we perform the requested invocation.
            Transaction memory transaction = invocation.transaction;

            require(
                transaction.to == address(this),
                "DelegatableCore:invalid-invocation-target"
            );

            // TODO(@kames): Can we bubble up the error message from the enforcer? Why not? Optimizations?
            success = _execute(
                transaction.to,
                transaction.data,
                transaction.gasLimit,
                intendedSender
            );
            require(success, "DelegatableCore::execution-failed");
        }
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../TypesAndDecoders.sol";

interface IDelegatable {
    /**
     * @notice Allows a smart contract to submit a batch of invocations for processing, allowing itself to be the delegate.
     * @param batch Invocation[] - The batch of invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function contractInvoke(Invocation[] calldata batch)
        external
        returns (bool);

    /**
     * @notice Allows anyone to submit a batch of signed invocations for processing.
     * @param signedInvocations SignedInvocation[] - The batch of signed invocations to process.
     * @return success bool - Whether the batch of invocations was successfully processed.
     */
    function invoke(SignedInvocation[] calldata signedInvocations)
        external
        returns (bool success);

    /**
     * @notice Returns the typehash for this contract's delegation signatures.
     * @param delegation Delegation - The delegation to get the type of
     * @return bytes32 - The type of the delegation
     */
    function getDelegationTypedDataHash(Delegation memory delegation)
        external
        view
        returns (bytes32);

    /**
     * @notice Returns the typehash for this contract's invocation signatures.
     * @param invocations Invocations
     * @return bytes32 - The type of the Invocations
     */
    function getInvocationsTypedDataHash(Invocations memory invocations)
        external
        view
        returns (bytes32);

    function getEIP712DomainHash(
        string memory contractName,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) external pure returns (bytes32);

    /**
     * @notice Verifies that the given invocation is valid.
     * @param signedInvocation - The signed invocation to verify
     * @return address - The address of the account authorizing this invocation to act on its behalf.
     */
    function verifyInvocationSignature(SignedInvocation memory signedInvocation)
        external
        view
        returns (address);

    /**
     * @notice Verifies that the given delegation is valid.
     * @param signedDelegation - The delegation to verify
     * @return address - The address of the account authorizing this delegation to act on its behalf.
     */
    function verifyDelegationSignature(SignedDelegation memory signedDelegation)
        external
        view
        returns (address);
}

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT

contract ECRecovery {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
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
            return ecrecover(hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT
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