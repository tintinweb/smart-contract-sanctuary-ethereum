// SPDX-License-Identifier: GPL-3.0

/**
 * @title Complete the Punks: Project
 * @dev Per-project contract for managing Bodies + Legs
 * @author earlybail.eth | Cranky Brain Labs
 * @notice #GetBodied #LegsFuknGooo
 */

/*
                   ;╟██▓▒              :╟██▓▒
                ,φ▒╣╬╬╩╩Γ               ╙╩╬╬╬▓▒░
              ,╓φ╣▓█╬Γ                     ╚╣█▓╬▒╓,                ,,╓╓╓╓,
             φ╣▓▓╬╩""                       ""╚╣▓▓▒░              ]╟▓████▓▒
          φφ╬╬╬╬╩╙                            '╚╩╬╬╬▒▒░           φ╫███▓╬╬╬▓▒░
         ]╟▓█▓▒                                  :╟▓█▓▒           φ╫██╬▒ ╚╣█▓╬φ,,
         :╟██▓▒                                  :╟██▓▒           φ╫██▓▒  "╙╠╣▓▓▒░
         :╟██▓▒                                  :╟██▓▒     φφ▒▒▒▒╬╬╬╩╩'    φ╫██▓▒
         :╟██▓▒      ,,,                         :╟██▓▒    ]╟▓████▓╬⌐       φ╫██▓▒
         :╟██▓▒    .╠╣▓▓▒                        :╟██▓▒    :╟███╬╩"'        φ╫██▓▒
         :╟██▓▒    :╟██▓▒     φφ▒φ░        ,φ▒▒░ :╟██▓▒    :╟██▓▒           φ╫██▓▒
         :╟██▓▒    :╟██▓▒    '╠▓█▓▒        ╚╣█▓╬⌐:╟███▒≥,  '╠▓█▓╬≥,       ,,φ╣██╬░
         :╟██▓▒    :╟██▓▒     ^"╙"'         "╙╙" :╟█████▓▒~ ^"╙╠╣▓▓▒~    φ╣▓▓╬╩╙"
         :╟██▓▒    :╟██▓▒                        :╟████▓╬╬▒▒φ  ╠▓██╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟███▒ ╚╟▓█╬▒╓╠▓██╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟██▓▒  "╙╚╣▓▓████╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟██▓▒     ╚╬╬████╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟███▒╓,      ╚╣██╬⌐    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟█████▓▒~    '"╙╙"     ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟████▓╬╬▒▒φ         ≤φ▒╬╬╬╬╚
         :╟██▓▒    :╟██▓▒                        :╟███▒ ╚╣██╬▒,,,,,,,φ╟▓█▓╩
         :╟██▓▒    :╟██▓▒                        :╟██▓▒  "╙╩╬╣▓▓▓▓▓▓▓▓╬╬╚╙'
         :╟██▓▒    :╟██▓▒                        :╟██▓▒     ╚╬▓▓▓▓▓▓▓╬╩░
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒           ]φ╣▓▒░       :╟██▓▒
         :╟██▓▒    :╟██▓▒           "╠╬▓╩░       :╟██▓▒
         :╟███▒,   :╟██▓▒                        :╟██▓▒
         :╟████▓▒▒ :╟██▓▒                        :╟██▓▒
          ╚╬█████▓▒▒╣██▓▒                        :╟██▓▒
            "╠▓████████▓▒                        :╟██▓▒
*/

/*
                φ╫██▓▒                           :╟██▓▒
                φ╫██▓▒    ,φ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░    :╟██▓▒
                φ╫██▓▒    φ╣███████████████▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓╩╙╙╙╙╙╙╙╚╣██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    "╩╬▓╬▒φφ,    :╟██▓▒     ╚╬▓╬╬▒φε
                φ╫██▓▒       7╟▓█▓▒,   ;╟██▓▒       `╠╣█▓╬░
                φ╫██▓▒        "╙╩╬╣▓▓▓▓▓███▓▒        ^╙╩╬╣▓▓▓▓▓▒░
                φ╫██▓▒           ╚╠╣███████▓▒           "╠╬████╬╬▒φε
                φ╫██▓▒              ```╠╠███▒,             ```░╠╣██╬[
                φ╫████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████╬[
                "╠╬███████████████████████████████████████████████╬╩
                  `^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/

// Directives.
pragma solidity 0.8.9;

// Third-party deps.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Local deps.
import "./Bodies.sol";
import "./Legs.sol";

// Contract.
contract Project is ReentrancyGuard, Ownable, PaymentSplitter {
    // Events.
    event StatusChange(Status _newStatus);

    // Mint statuses.
    enum Status {
        Paused,
        Whitelist,
        Mintpass,
        Public
    }

    // Current mint status, defaults to Status[0] (Paused).
    Status public status;

    // Bodies.
    Bodies public bodies;

    // Legs.
    Legs public legs;

    // Pricing.
    // @notice settable, use mintPrice() for latest.
    uint256 public whitelistPrice = 0.02 ether;
    uint256 public mintpassPrice = 0.04 ether;
    uint256 public publicPrice = 0.04 ether;

    // Mint limits.
    // @notice settable, use mintLimit() for latest.
    uint256 public whitelistMintLimit = 4;
    uint256 public mintpassMintLimit = 20;
    uint256 public publicMintLimit = 40;

    // Max tokens.
    uint256 public maxSupply = 10000;

    // Mintpassed contracts.
    address[] public mintpassedContracts;

    // Whitelist Merkle root.
    bytes32 public merkleRoot = 0x05ba199ba71527baf0f85acf24728a2e559447f3228c1ff56d0d90f8bb269f7d;

    // Constructor.
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _tokenStartId,
        address[] memory _payees,
        uint256[] memory _shares
    ) PaymentSplitter(_payees, _shares) {
        // Deploy and set Bodies contract.
        bodies = new Bodies(
            string(abi.encodePacked(_name, ": Bodies")), // Extend name.
            string(abi.encodePacked(_symbol, "B")), // Extend symbol.
            _tokenStartId
        );

        // Set this Project contract as parent project.
        bodies.setProjectAddress(address(this));

        // Transfer bodies contract ownership to deployer.
        bodies.transferOwnership(_msgSender());

        // Deploy and set Legs contract.
        legs = new Legs(
            string(abi.encodePacked(_name, ": Legs")), // Extend name.
            string(abi.encodePacked(_symbol, "L")), // Extend symbol.
            _tokenStartId
        );

        // Set this Project contract as parent project.
        legs.setProjectAddress(address(this));

        // Transfer legs contract ownership to deployer.
        legs.transferOwnership(_msgSender());
    }

    // Mint check helper.
    modifier mintCheck (address _to, uint256 _numToMint) {
        // Early bail if paused.
        require(status != Status.Paused, "Minting is paused");

        // Ensure sender.
        require(_to == _msgSender(), "Can only mint for self");

        // Protect against contract minting.
        require(!Address.isContract(_msgSender()), "Cannot mint from contract");

        // Ensure non-zero mint amount.
        require(_numToMint > 0, "Cannot mint zero tokens");

        // Ensure available supply.
        require(totalSupply() + _numToMint <= maxSupply, "Max supply exceeded");

        // Ensure mint limit not exceeded.
        require(_numToMint <= mintLimit(), "Cannot mint this many tokens");

        // Ensure proper payment.
        require(msg.value == _numToMint * mintPrice(), "Incorrect payment amount sent");

        _;
    }

    // Set mint price.
    function setPrice (Status _status, uint256 _newPrice) external onlyOwner {
        if (_status == Status.Whitelist) {
            whitelistPrice = _newPrice;
        }

        if (_status == Status.Mintpass) {
            mintpassPrice = _newPrice;
        }

        if (_status == Status.Public) {
            publicPrice = _newPrice;
        }
    }

    // Set mint limit.
    function setMintLimit (Status _status, uint256 _newLimit) external onlyOwner {
        if (_status == Status.Whitelist) {
            whitelistMintLimit = _newLimit;
        }

        if (_status == Status.Mintpass) {
            mintpassMintLimit = _newLimit;
        }

        if (_status == Status.Public) {
            publicMintLimit = _newLimit;
        }
    }

    // Set the bodies contract.
    function setBodies (address _newAddr) external onlyOwner {
        bodies = Bodies(_newAddr);
    }

    // Set the legs contract.
    function setLegs (address _newAddr) external onlyOwner {
        legs = Legs(_newAddr);
    }

    // (Re-)set the whitelist Merkle root.
    function setMerkleRoot (bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    // Set the mint status.
    function setStatus (Status _newStatus) external onlyOwner {
        // Update.
        status = _newStatus;

        // Broadcast.
        emit StatusChange(_newStatus);
    }

    // (Re-)set the list of Mintpassed Contracts.
    function setMintpassedContracts (address[] calldata _newAddrs) external onlyOwner {
        delete mintpassedContracts;
        mintpassedContracts = _newAddrs;
    }

    // Add a new Mintpassed Contract.
    function addMintpassedContract (address _addr) external onlyOwner {
        mintpassedContracts.push(_addr);
    }

    // Check if an address is whitelisted via Merkle proof validation.
    function isWhitelistedAddress (address _addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        // Verify Merkle tree proof.
        bytes32 leaf = keccak256(abi.encodePacked(_addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // Check if an address is mintpassed (has a balance on a Mintpassed Contract).
    function isMintpassedAddress (address _addr) public view returns (bool) {
        // Cache array length to save gas.
        uint256 len = mintpassedContracts.length;

        // Loop through Mintpassed Contracts.
        for (uint256 i = 0; i < len; i++) {
            // Instantiate this Mintpassed Contract.
            MintpassedContract mintpassedContract = MintpassedContract(mintpassedContracts[i]);

            // Check if the address has a non-zero balance.
            if (mintpassedContract.balanceOf(_addr) > 0) {
                return true;
            }
        }

        // Not allowed.
        return false;
    }

    // Proxy supply to bodies.
    function totalSupply () public view returns (uint256) {
        return bodies.totalSupply();
    }

    // Proxy balance to bodies.
    function balanceOf (address _owner) public view returns (uint256) {
        return bodies.balanceOf(_owner);
    }

    // Dynamic mint price.
    function mintPrice () public view returns (uint256) {
        // Paused.
        if (status == Status.Paused) {
            // Failsafe, but if you find a way go for it.
            return 1000000 ether;
        }

        // Whitelist.
        if (status == Status.Whitelist) {
            return whitelistPrice;
        }

        // Mintpass.
        if (status == Status.Mintpass) {
            return mintpassPrice;
        }

        // Public.
        return publicPrice;
    }

    // Dynamic mint limit.
    function mintLimit () public view returns (uint256) {
        // Paused.
        if (status == Status.Paused) {
            return 0;
        }

        // Whitelist.
        if (status == Status.Whitelist) {
            return whitelistMintLimit;
        }

        // Mintpass.
        if (status == Status.Mintpass) {
            return mintpassMintLimit;
        }

        // Public.
        return publicMintLimit;
    }

    // Mint.
    function mint (address _to, uint256 _numToMint) external payable nonReentrant mintCheck(_to, _numToMint) {
        // Not for whitelist mints.
        require(status != Status.Whitelist, "Whitelist mints must provide proof via mintWhitelist()");

        // Mintpass.
        if (status == Status.Mintpass) {
            // Check eligibility.
            require(isMintpassedAddress(_to), "Address is not mintpassed");
        }

        // Okay mint.
        _mint(_to, _numToMint);
    }

    // Mint whitelist.
    function mintWhitelist (address _to, uint256 _numToMint, bytes32[] calldata _merkleProof) external payable nonReentrant mintCheck(_to, _numToMint) {
        // Require whitelist status.
        require(status == Status.Whitelist, "Whitelist mints only");

        // Check balance.
        require((balanceOf(_to) + _numToMint) <= mintLimit(), "Whitelist mint limit exceeded");

        // Check whitelist eligibility.
        require(isWhitelistedAddress(_to, _merkleProof), "Address is not whitelisted");

        // Okay mint.
        _mint(_to, _numToMint);
    }

    // Actually mint.
    function _mint (address _to, uint256 _numToMint) private {
        // Mint bodies & legs.
        bodies.mint(_to, _numToMint);
        legs.mint(_to, _numToMint);
    }
}

// Mintpassed Contract interface.
interface MintpassedContract {
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

/**
 * @title Complete the Punks: Bodies
 * @dev Mints Body NFTs for a parent Punk project
 * @author earlybail.eth | Cranky Brain Labs
 * @notice #GetBodied
 */

/*
                   ;╟██▓▒              :╟██▓▒
                ,φ▒╣╬╬╩╩Γ               ╙╩╬╬╬▓▒░
              ,╓φ╣▓█╬Γ                     ╚╣█▓╬▒╓,                ,,╓╓╓╓,
             φ╣▓▓╬╩""                       ""╚╣▓▓▒░              ]╟▓████▓▒
          φφ╬╬╬╬╩╙                            '╚╩╬╬╬▒▒░           φ╫███▓╬╬╬▓▒░
         ]╟▓█▓▒                                  :╟▓█▓▒           φ╫██╬▒ ╚╣█▓╬φ,,
         :╟██▓▒                                  :╟██▓▒           φ╫██▓▒  "╙╠╣▓▓▒░
         :╟██▓▒                                  :╟██▓▒     φφ▒▒▒▒╬╬╬╩╩'    φ╫██▓▒
         :╟██▓▒      ,,,                         :╟██▓▒    ]╟▓████▓╬⌐       φ╫██▓▒
         :╟██▓▒    .╠╣▓▓▒                        :╟██▓▒    :╟███╬╩"'        φ╫██▓▒
         :╟██▓▒    :╟██▓▒     φφ▒φ░        ,φ▒▒░ :╟██▓▒    :╟██▓▒           φ╫██▓▒
         :╟██▓▒    :╟██▓▒    '╠▓█▓▒        ╚╣█▓╬⌐:╟███▒≥,  '╠▓█▓╬≥,       ,,φ╣██╬░
         :╟██▓▒    :╟██▓▒     ^"╙"'         "╙╙" :╟█████▓▒~ ^"╙╠╣▓▓▒~    φ╣▓▓╬╩╙"
         :╟██▓▒    :╟██▓▒                        :╟████▓╬╬▒▒φ  ╠▓██╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟███▒ ╚╟▓█╬▒╓╠▓██╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟██▓▒  "╙╚╣▓▓████╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟██▓▒     ╚╬╬████╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟███▒╓,      ╚╣██╬⌐    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟█████▓▒~    '"╙╙"     ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟████▓╬╬▒▒φ         ≤φ▒╬╬╬╬╚
         :╟██▓▒    :╟██▓▒                        :╟███▒ ╚╣██╬▒,,,,,,,φ╟▓█▓╩
         :╟██▓▒    :╟██▓▒                        :╟██▓▒  "╙╩╬╣▓▓▓▓▓▓▓▓╬╬╚╙'
         :╟██▓▒    :╟██▓▒                        :╟██▓▒     ╚╬▓▓▓▓▓▓▓╬╩░
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒           ]φ╣▓▒░       :╟██▓▒
         :╟██▓▒    :╟██▓▒           "╠╬▓╩░       :╟██▓▒
         :╟███▒,   :╟██▓▒                        :╟██▓▒
         :╟████▓▒▒ :╟██▓▒                        :╟██▓▒
          ╚╬█████▓▒▒╣██▓▒                        :╟██▓▒
            "╠▓████████▓▒                        :╟██▓▒
*/

// Directives.
pragma solidity 0.8.9;

// Local deps.
import "./Component.sol";

// Contract.
contract Bodies is Component {
    // Constructor.
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _tokenStartId
    ) Component(_name, _symbol, _tokenStartId) {}
}

// SPDX-License-Identifier: MIT

/**
 * @title Complete the Punks: Legs
 * @dev Mints Leg NFTs for a parent Punk project
 * @author earlybail.eth | Cranky Brain Labs
 * @notice #LegsFuknGooo
 */

/*
                φ╫██▓▒                           :╟██▓▒
                φ╫██▓▒    ,φ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░    :╟██▓▒
                φ╫██▓▒    φ╣███████████████▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓╩╙╙╙╙╙╙╙╚╣██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    "╩╬▓╬▒φφ,    :╟██▓▒     ╚╬▓╬╬▒φε
                φ╫██▓▒       7╟▓█▓▒,   ;╟██▓▒       `╠╣█▓╬░
                φ╫██▓▒        "╙╩╬╣▓▓▓▓▓███▓▒        ^╙╩╬╣▓▓▓▓▓▒░
                φ╫██▓▒           ╚╠╣███████▓▒           "╠╬████╬╬▒φε
                φ╫██▓▒              ```╠╠███▒,             ```░╠╣██╬[
                φ╫████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████╬[
                "╠╬███████████████████████████████████████████████╬╩
                  `^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/

// Directives.
pragma solidity 0.8.9;

// Local deps.
import "./Component.sol";

// Contract.
contract Legs is Component {
    // Constructor.
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _tokenStartId
    ) Component(_name, _symbol, _tokenStartId) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT

/**
 * @title Complete the Punks: Component
 * @dev Base component contract for Bodies + Legs
 * @author earlybail.eth | Cranky Brain Labs
 * @notice #GetBodied #LegsFuknGooo
 */

// Directives.
pragma solidity 0.8.9;

// Third-party deps.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Contract.
contract Component is ERC721, ReentrancyGuard, Ownable {
    // Strings.
    using Strings for uint256;

    // Counters.
    using Counters for Counters.Counter;

    // Supply counter.
    Counters.Counter private _supply;

    // Parent Project contract address.
    address public projectAddress;

    // OpenSea Proxy contract address.
    address public openSeaProxyContractAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    // Base URI.
    string public baseURI;

    // Base extension.
    string public baseExtension = "";

    // Provenance hash.
    string public provenanceHash;

    // Mint ID tracking.
    mapping(uint256 => uint256) private _tokenIdCache;
    uint256 public remainingTokenCount = 10000;

    // Token start ID.
    uint256 public tokenStartId = 0;

    // Constructor.
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _tokenStartId
    ) ERC721(_name, _symbol) {
        // Set token start ID.
        tokenStartId = _tokenStartId;
    }

    // Only allow the project contract as caller.
    modifier onlyProject () {
        require(_msgSender() == projectAddress, "Only the parent Project contract can call this method");
        _;
    }

    // Get base URI.
    function _baseURI () internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Set project address.
    function setProjectAddress (address _newAddr) external onlyOwner {
        projectAddress = _newAddr;
    }

    // Set base URI.
    function setBaseURI (string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // Set base extension.
    function setBaseExtension (string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // Set the token start ID.
    function setTokenStartId (uint256 _newId) external onlyOwner {
        tokenStartId = _newId;
    }

    // Set provenance hash.
    function setProvenanceHash (string memory _newHash) external onlyOwner {
        provenanceHash = _newHash;
    }

    // Set OpenSea proxy address.
    // Rinkeby: 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    // Mainnet: 0xa5409ec958C83C3f309868babACA7c86DCB077c1
    // Disable: 0x0000000000000000000000000000000000000000
    function setOpenSeaProxyAddress (address _newAddress) external onlyOwner {
        openSeaProxyContractAddress = _newAddress;
    }

    // Token URI.
    function tokenURI (uint256 _tokenId) public view virtual override returns (string memory) {
        // Ensure existence.
        require(_exists(_tokenId), "Query for non-existent token");

        // Cache.
        string memory currentBaseURI = _baseURI();

        // Concatenate.
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
            : "";
    }

    // Get the current total supply.
    function totalSupply () public view returns (uint256) {
        return _supply.current();
    }

    // Mint.
    function mint (address _to, uint256 _numToMint) public nonReentrant onlyProject {
        _mintLoop(_to, _numToMint);
    }

    // Actually mint.
    function _mintLoop (address _to, uint256 _numToMint) private {
        for (uint256 i = 0; i < _numToMint; i++) {
            // Draw ID.
            uint256 tokenId = drawTokenId();

            // Safe mint.
            _safeMint(_to, tokenId);

            // Increment supply counter.
            _supply.increment();
        }
    }

    // Draw token ID.
    function drawTokenId () private returns (uint256) {
        // Generate an index.
        uint256 num = uint256(
            keccak256(
                abi.encode(
                    _msgSender(),
                    name(),
                    symbol(),
                    blockhash(block.number - 1),
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    tx.gasprice,
                    remainingTokenCount,
                    projectAddress
                )
            )
        );

        // Mod.
        uint256 index = num % remainingTokenCount;

        // If we haven't already drawn this index, use it directly as tokenId.
        // Otherwise, pull the tokenId we cached at this index last time.
        uint256 tokenId = _tokenIdCache[index] == 0
            ? index
            : _tokenIdCache[index];

        // Cache this index with the tail of remainingTokenCount.
        _tokenIdCache[index] = _tokenIdCache[remainingTokenCount - 1] == 0
            ? remainingTokenCount - 1
            : _tokenIdCache[remainingTokenCount - 1];

        // Decrement remaining tokens.
        remainingTokenCount = remainingTokenCount - 1;

        // Return with optional start offset.
        return tokenId + tokenStartId;
    }

    // Public exists.
    function exists (uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    // Override operator approval.
    function isApprovedForAll (address _owner, address _operator) public override view returns (bool) {
        // Skip if disabled.
        if (openSeaProxyContractAddress != address(0)) {
            // Instantiate proxy registry.
            ProxyRegistry proxyRegistry = ProxyRegistry(openSeaProxyContractAddress);

            // Check proxy.
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }

        // Defer.
        return super.isApprovedForAll(_owner, _operator);
    }
}

// Proxy.
contract OwnableDelegateProxy {}

// Proxy registry.
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
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

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
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

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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